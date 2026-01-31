# CogniCare Website

This folder contains the landing page website for CogniCare, built with Flutter for Web.

## Structure

- `landing_page.dart` - Main landing page with responsive design
- `main_web.dart` - Entry point for the website

## Features

- **Responsive Design**: Adapts to mobile (<768px) and desktop layouts
- **Hero Section**: Compelling tagline and app description
- **Download Buttons**: Direct links to App Store and Google Play
- **Features Grid**: Highlights 4 key app features
- **Footer**: Copyright and policy links

## Quick Start

From the project root:

```bash
cd frontend
flutter pub get
flutter run -d chrome --target lib/website/main_web.dart
```

The website will open in Chrome at `http://localhost:port`

## Running the Website Locally

### Development Mode

In Chrome browser:
```bash
cd frontend
flutter run -d chrome --target lib/website/main_web.dart
```

Or use the web server (access from any browser):
```bash
flutter run -d web-server --target lib/website/main_web.dart
```

This will give you a URL like `http://localhost:8080` that you can open in any browser.

### Production Build

```bash
cd frontend
flutter build web --target lib/website/main_web.dart --release
```

The output will be in `frontend/build/web/` directory.

## Deployment

### Firebase Hosting

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Login and initialize:
```bash
firebase login
firebase init hosting
```

3. Configure `firebase.json`:
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

4. Deploy:
```bash
flutter build web --target lib/website/main_web.dart --release
firebase deploy --only hosting
```

### Netlify

1. Build the website:
```bash
flutter build web --target lib/website/main_web.dart --release
```

2. Deploy via Netlify CLI or drag & drop the `build/web` folder to Netlify dashboard

### Vercel

1. Install Vercel CLI:
```bash
npm install -g vercel
```

2. Build and deploy:
```bash
flutter build web --target lib/website/main_web.dart --release
cd build/web
vercel --prod
```

### GitHub Pages

1. Build the website:
```bash
flutter build web --target lib/website/main_web.dart --release --base-href "/cognicare-mobile/"
```

2. Copy `build/web` contents to a `gh-pages` branch or `docs/` folder

3. Enable GitHub Pages in repository settings

## Customization

### Update App Store URLs

Edit `landing_page.dart` and update the URLs in the download buttons:

```dart
// iOS App Store
_launchURL('https://apps.apple.com/app/your-app-id');

// Google Play Store
_launchURL('https://play.google.com/store/apps/details?id=your.package.name');
```

### Update Colors

The website uses the same color scheme as the mobile app from `AppTheme`:
- Primary: #A4D7E1
- Secondary: #A7E9A4
- Accent: #F9D51C
- Text: #5A5A5A
- Background: #F6F6F6

To customize, update the colors in [frontend/lib/utils/theme.dart](../utils/theme.dart).

### Add More Sections

You can add additional sections to the landing page:
- Screenshots carousel
- Testimonials
- Pricing plans
- Contact form
- FAQ section

## SEO Optimization

The website includes:
- Meta tags for description and keywords
- Open Graph tags for social media sharing
- Twitter Card tags
- Semantic HTML structure

Update the meta tags in `web/index_website.html` for better SEO.

## Performance Tips

1. **Build in release mode** for production:
```bash
flutter build web --target lib/website/main_web.dart --release
```

2. **Enable caching** in your hosting provider

3. **Use CDN** for faster global delivery

4. **Optimize images** before adding to the website

5. **Lazy load** non-critical content

## Analytics

To add Google Analytics:

1. Add `google_analytics` package to `pubspec.yaml`
2. Initialize in `main_web.dart`
3. Track page views and button clicks

## Testing

Test responsive design:
```bash
flutter run -d chrome --target lib/website/main_web.dart
```

Then use Chrome DevTools to test different screen sizes.

## Browser Support

The website supports:
- Chrome (recommended)
- Firefox
- Safari
- Edge
- Mobile browsers

## Notes

- The website is a separate entry point from the main app
- Uses the same theme and localization system
- Optimized for SEO and fast loading
- Mobile-first responsive design
