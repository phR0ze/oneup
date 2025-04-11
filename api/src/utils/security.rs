
/// Generate the user's password hash
/// - Generate a random salt and concate it with the password
/// - Hash the salt/password combination using SHA256
/// - `hash` is the resulting hash
fn hash_password(password: &str) -> String {
    // // Generate a random salt
    // let salt = rand::rng().gen::<[u8; 16]>();
    // // Concatenate the salt and password
    // let salted_password = [salt.as_ref(), password.as_bytes()].concat();
    // // Hash the salted password using SHA256
    // let hash = Sha256::digest(&salted_password);
    // // Convert the hash to a hex string
    // format!("{:x}", hash)
    "".to_string()
}