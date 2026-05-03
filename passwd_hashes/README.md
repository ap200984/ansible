### Generate sha512 hash
openssl -6 'my_password'

this command uses salt by default (adds random string to password before hashing).
So the same password has defferent hash everytime
