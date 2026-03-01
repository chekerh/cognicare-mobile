/**
 * Automatisation Puppeteer pour soumettre la commande sur BioHerbs
 * afin que le client reçoive l’email de confirmation réel de BioHerbs.
 */
import puppeteer from 'puppeteer';

const BIOHERBS_BASE = 'https://www.bioherbs.tn';

export interface BioherbsCheckoutData {
  variantId: number;
  quantity: number;
  formData: Record<string, string>;
}

export interface BioherbsCheckoutResult {
  success: boolean;
  externalOrderId?: string;
  error?: string;
}

/**
 * Lance le navigateur, ajoute au panier, va au checkout, remplit le formulaire et soumet.
 * En cas de succès, BioHerbs envoie leur email de confirmation au client.
 */
export async function submitBioherbsOrderWithPuppeteer(
  data: BioherbsCheckoutData,
): Promise<BioherbsCheckoutResult> {
  const d = data.formData;
  const email = d.email?.trim() || '';
  const firstName = d.firstName?.trim() || d.fullName?.trim() || '';
  const lastName = d.lastName?.trim() || '';
  const address = d.address?.trim() || '';
  const city = d.city?.trim() || '';
  const postalCode = d.postalCode?.trim() || '';
  const phone = d.phone?.trim() || '';

  if (!email) {
    return { success: false, error: 'Email requis' };
  }

  let browser: Awaited<ReturnType<typeof puppeteer.launch>> | null = null;

  try {
    browser = await puppeteer.launch({
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-gpu',
      ],
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 800 });
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    );

    const timeout = 60000;
    page.setDefaultTimeout(timeout);

    // 1) Ajouter au panier via l’API dans le contexte de la page (même origine)
    await page.goto(BIOHERBS_BASE, { waitUntil: 'networkidle2' }).catch(() => {});

    const addResult = await page.evaluate(
      async (args: { variantId: number; quantity: number }) => {
        const res = await fetch(`${window.location.origin}/cart/add.js`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            items: [{ id: args.variantId, quantity: args.quantity }],
          }),
        });
        return { ok: res.ok, status: res.status };
      },
      { variantId: data.variantId, quantity: data.quantity },
    );

    if (!addResult?.ok) {
      return { success: false, error: 'Échec ajout au panier' };
    }

    // 2) Aller au checkout
    await page.goto(`${BIOHERBS_BASE}/checkout`, { waitUntil: 'networkidle2' }).catch(() => {});

    const url = page.url();
    if (!url.includes('checkout')) {
      return { success: false, error: 'Page checkout non atteinte' };
    }

    // 3) Remplir l’email (contact)
    const emailSelector = [
      'input[name="checkout[email]"]',
      'input[name="contact[email]"]',
      '#checkout_email',
      'input[type="email"]',
    ];
    for (const sel of emailSelector) {
      try {
        await page.waitForSelector(sel, { timeout: 5000 });
        await page.type(sel, email, { delay: 50 });
        break;
      } catch {
        continue;
      }
    }

    // 4) Continuer vers l’adresse (bouton "Continue" / "Continuer")
    const continueSelectors = [
      'button[name="button"]',
      'input[type="submit"]',
      'button[type="submit"]',
      '[data-trekkie-id="continue_to_shipping_method_button"]',
      'button:has-text("Continuer")',
      'button:has-text("Continue")',
    ];
    for (const sel of continueSelectors) {
      try {
        const btn = await page.$(sel);
        if (btn) {
          await btn.click();
          await page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 15000 }).catch(() => {});
          break;
        }
      } catch {
        continue;
      }
    }

    // 5) Remplir l’adresse de livraison (sélecteurs courants Shopify)
    const fillSelectors: Array<[string, string]> = [
      ['input[name="checkout[shipping_address][first_name]"]', firstName],
      ['input[name="checkout[shipping_address][last_name]"]', lastName],
      ['input[name="checkout[shipping_address][address1]"]', address],
      ['input[name="checkout[shipping_address][city]"]', city],
      ['input[name="checkout[shipping_address][zip]"]', postalCode],
      ['input[name="checkout[shipping_address][phone]"]', phone],
    ];
    for (const [sel, value] of fillSelectors) {
      if (!value) continue;
      try {
        const el = await page.$(sel);
        if (el) {
          await el.click({ clickCount: 3 });
          await el.type(value, { delay: 30 });
        }
      } catch {
        // ignorer si le champ n’existe pas
      }
    }

    // Pays : sélecteur ou input
    try {
      await page.select('select[name="checkout[shipping_address][country]"]', 'TN').catch(() => {});
    } catch {
      // pays peut être pré-rempli
    }

    // 6) Sélectionner "Paiement à la livraison" si présent (pour pouvoir passer commande sans carte)
    await new Promise((r) => setTimeout(r, 1000));
    await page.evaluate(() => {
      const labels = Array.from(document.querySelectorAll('label, span, div[role="button"]'));
      for (const el of labels) {
        const t = (el.textContent || '').toLowerCase();
        if (t.includes('livraison') && (t.includes('paiement') || t.includes('payment') || t.includes('cash'))) {
          el.click();
          break;
        }
      }
      const radios = Array.from(document.querySelectorAll('input[type="radio"]'));
      for (const r of radios) {
        const label = r.closest('label') || document.querySelector(`label[for="${r.id}"]`);
        if (label && /livraison|delivery|cash/i.test(label.textContent || '')) {
          (r as HTMLInputElement).click();
          break;
        }
      }
    });

    // 7) Cliquer sur "Continuer" jusqu'à l'étape paiement, puis "Passer la commande"
    const continueButtonTexts = ['Continuer', 'Continue', 'Next', 'Suivant'];
    const completeOrderTexts = ['Passer la commande', 'Complete order', 'Commander', 'Pay now', 'Payer maintenant'];

    for (let step = 0; step < 5; step++) {
      await new Promise((r) => setTimeout(r, 1500));
      const clicked = await page.evaluate(
        (continueTexts: string[], completeTexts: string[]) => {
          const buttons = Array.from(document.querySelectorAll('button, [type="submit"], input[type="submit"]'));
          for (const btn of buttons) {
            const text = (btn.textContent || '').trim();
            if (completeTexts.some((t) => text.toLowerCase().includes(t.toLowerCase()))) {
              (btn as HTMLElement).click();
              return 'complete';
            }
            if (continueTexts.some((t) => text.toLowerCase().includes(t.toLowerCase()))) {
              (btn as HTMLElement).click();
              return 'continue';
            }
          }
          return null;
        },
        continueButtonTexts,
        completeOrderTexts,
      );
      if (clicked === 'complete') break;
      await page.waitForNavigation({ waitUntil: 'networkidle0', timeout: 12000 }).catch(() => {});
    }

    // 8) Attendre la page de remerciement ou un numéro de commande
    await new Promise((r) => setTimeout(r, 4000));
    const thankYouContent = await page.content();
    const orderMatch =
      thankYouContent.match(/COMMANDE\s*#?(\d+)/i) ||
      thankYouContent.match(/order[_\s]?(?:number|#)?\s*(\d+)/i) ||
      thankYouContent.match(/#(\d{4,})/);
    const externalOrderId = orderMatch ? orderMatch[1] : undefined;

    const isThankYouPage =
      thankYouContent.includes('Merci') ||
      thankYouContent.includes('Thank you') ||
      thankYouContent.includes('confirmation') ||
      thankYouContent.includes('votre achat') ||
      thankYouContent.includes('order confirmed');

    if (isThankYouPage) {
      return { success: true, externalOrderId };
    }

    return { success: false, error: 'Confirmation de commande non détectée (étape paiement ou bouton final non atteinte)', externalOrderId };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return { success: false, error: message };
  } finally {
    if (browser) {
      await browser.close().catch(() => {});
    }
  }
}
