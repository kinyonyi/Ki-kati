const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  email: {
    type: String,
    required: true,
    unique: true,
    validate: {
      validator: function (v) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v); // Simple email regex
      },
      message: (props) => `${props.value} is not a valid email!`,
    },
  },
  groups: [{ type: mongoose.Schema.Types.ObjectId, ref: "Group" }], // Array of Group references
  isEmailConfirmed: { type: Boolean, default: false }, // Email confirmation status
  confirmationCode: { type: String }, // Confirmation code
  confirmationCodeExpires: { type: Date }, // Code expiration time
});

module.exports = mongoose.model("User", UserSchema);
