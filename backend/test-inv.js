const mongoose = require('mongoose');

mongoose.connect('mongodb://localhost:27017/cognicare', {})
.then(async () => {
  const InvitationSchema = new mongoose.Schema({}, { strict: false, collection: 'invitations' });
  const Invitation = mongoose.model('Invitation', InvitationSchema);
  
  const UserSchema = new mongoose.Schema({}, { strict: false, collection: 'users' });
  const User = mongoose.model('User', UserSchema);

  const invs = await Invitation.find({ status: 'pending' }).sort({ createdAt: -1 }).limit(1).lean();
  console.log('Last pending invitation:', JSON.stringify(invs, null, 2));

  if (invs.length > 0) {
     const user = await User.findById(invs[0].userId).lean();
     console.log('User associated:', JSON.stringify(user, null, 2));
  }

  mongoose.connection.close();
})
.catch(console.error);
