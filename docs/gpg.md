# Working with GPG keys #

## Overview of setting up a new Riff GPG key

1. Create a new key for your rifflearning.com email
1. Add a subkey for signing
1. Export your public key to a keyserver
1. Import your coworkers keys from the keyserver
1. Use a secure channel to verify your coworker's key fingerprints and **ONLY** after verification,
   sign them and export them back to the keyserver
1. Have your coworkers verify your key's fingerprint and then sign and export your key back to the keyserver
1. Backup your key (private/public) in a safe place (or 2)

The following document should help you to accomplish these steps.


## Create a GPG key ##

Use the gpg2 command:
```sh
gpg2 --full-gen-key
```
or the gpg command:
```
gpg --gen-key
```

Select:

- **1** : RSA and RSA (default)
- **4096** : keysize
- **3y** : key should expire in 3 years (it is easy to reset even after it expires, you may want a shorter expiration, I wouldn't use a longer one)
- _Your full name_ : people may search key servers for this
- _Your email address_
- leave comment **blank**
- Use a strong passphrase : when I did this from the terminal prompt in linux a separate window opened for me to enter the passphrase

Here's an example console log of running the gpg2 command:
```console
$ gpg2 --full-gen-key
gpg (GnuPG) 2.1.11; Copyright (C) 2016 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
Your selection? 1
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (2048) 4096
Requested keysize is 4096 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 3y
Key expires at Thu 27 Oct 2022 05:37:35 PM EDT
Is this correct? (y/N) y

GnuPG needs to construct a user ID to identify your key.

Real name: Beth Porter
Email address: beth@rifflearning.com
Comment: 
You selected this USER-ID:
    "Beth Porter <beth@rifflearning.com>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? o
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
```

### Add a new subkey for signing to the key you just created

(These instructions are copied from [Using OpenPGP subkeys in Debian development][debian subkeys])

- Find your key ID: `gpg --list-keys yourname`
- `gpg --edit-key YOURMASTERKEYID`
- At the `gpg>` prompt: `addkey`
    - This asks for your passphrase, type it in.
    - Choose the "RSA (sign only)" key type.
    - It would be wise to choose 4096 (or 2048) bit key size.
    - Choose an expiry date (you can rotate your subkeys more frequently than the master keys, or keep them for the life of the master key, with no expiry).
    - GnuPG will (eventually) create a key, but you may have to wait for it to get enough entropy to do so.
- Save the key: `save`

Note the key IDs were not be displayed by ver 2.2.4 of gpg2 output for the various `--list*` options,
adding the option `--keyid-format long` shows the ID again.


## Find and import a GPG key ##

To search for a key on the ubuntu keyserver:

```sh
gpg --keyserver keyserver.ubuntu.com --search-keys 'jordan reedie'
gpg --keyserver keyserver.ubuntu.com --search-keys 'jordan@rifflearning.com'
```

To display a key fingerprint:

```sh
gpg2 --fingerprint jordan@rifflearning.com
```

## Sign and export a GPG key ##

### sign ###
To sign a key once you've **verified** it (via matching the fingerprint obtained via a secure
channel preferably interactive, or in person):

```console
$ gpg2 --sign-key --ask-cert-level jordan@rifflearning.com

pub  rsa4096/85F55F59
     created: 2019-09-24  expires: 2020-09-23  usage: SC
     trust: unknown       validity: unknown
sub  rsa4096/19AE50F7
     created: 2019-09-24  expires: 2020-09-23  usage: E
[ unknown] (1). Jordan Reedie <jordan@rifflearning.com>


pub  rsa4096/85F55F59
     created: 2019-09-24  expires: 2020-09-23  usage: SC
     trust: unknown       validity: unknown
 Primary key fingerprint: 04DF 7FE9 6E21 AA2F C034  01BB D0D0 0361 85F5 5F59

     Jordan Reedie <jordan@rifflearning.com>

This key is due to expire on 2020-09-23.
How carefully have you verified the key you are about to sign actually belongs
to the person named above?  If you don't know what to answer, enter "0".

   (0) I will not answer. (default)
   (1) I have not checked at all.
   (2) I have done casual checking.
   (3) I have done very careful checking.

Your selection? (enter '?' for more information): 3
Are you sure that you want to sign this key with your
key "Michael Jay Lippert <mike@rifflearning.com>" (6A9A3282)

I have checked this key very carefully.

Really sign? (y/N) y
```

### export the signed key ###
```
$ gpg2 --keyserver keyserver.ubuntu.com --send-keys 85F55F59
```

Note the last command above to send the signed key back to the keyserver (uses the key ID)

### import the signed key ###
Then the owner of the key should be able to import the newly signed key using:
```
gpg --keyserver keyserver.ubuntu.com --recv-keys 85F55F59
```

Note I'm finding that frequently `gpg` is getting data from the keyserver more successfully than
`gpg2`?! _(from trying it on 2019-09-26)_

## Safety

Even if you don't remove your master key from your primary computer system, if you want to
sign/encrypt/decrypt on other machines, it would be wise to _only_ put your subkeys on that
machine and NOT your master key.

Also you should create a revocation certificate for your master key. See [this page][rh-revocation] for more
on the topic.

Creating useful backup files (**make sure you keep the secret ones somewhere secure!**):
```
gpg2 --output=GPG_namehereMaster_RevocationCertificate.asc --gen-revoke name@somewhere.org
gpg2 --armor --output=GPG_namehereMaster_PrivateKey.asc --export-secret-keys name@somewhere.org
gpg2 --armor --output=GPG_namehereSecretSubkeys.asc --export-secret-subkeys name@somewhere.org
gpg2 --armor --output=GPG_nameherePublicKey.asc --export name@somewhere.org
```

Copy the SecretSubkeys file to the other system where you want to be able to sign/encrypt/decrypt
and import it.
```
gpg2 --import GPG_namehereSecretSubkeys.asc
```

When you list the secret keys on that machine (`gpg2 --list-secret-keys`) you should see your
master key identified with `sec#`. The `#` suffix means that the secret master key is not present.

## Resources

- [The GNU Privacy Handbook: Key Management][gpg_keymgmt]
- [GPG Tutorial][]
- [Redhat Appendix B. Getting Started with Gnu Privacy Guard][redhat-gpg-doc]
- [PGP Key Signing][pgp-key-signing]
- [Check encrypted file recipients][check-file-recipients]
  `gpg2 --batch --list-packets somefile.gpg | grep '^gpg:'`
- [gpg2 man page][gpg2-man]
- [Creating gpg key guide][] - Blog post on Create GnuPG key with sub-keys to sign, encrypt, authenticate
- [debian subkeys][] - Using subkeys makes key management easier, also explains how to keep your master key separate

### Keyservers
- [Ubuntu PGP Key Server][] - Has been a good one to use so far.
- [OpenPGPkeyserver][]
- [MIT PGP Public Key Server][]


[gpg_keymgmt]: <https://www.gnupg.org/gph/en/manual/c235.html>
[GPG Tutorial]: <https://futureboy.us/pgp.html>
[redhat-gpg-doc]: <https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/4/html/Step_by_Step_Guide/ch-gnupg.html>
[rh-revocation]: <https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/4/html/Step_by_Step_Guide/s1-gnupg-revocation.html>
[pgp-key-signing]: <https://www.phildev.net/pgp/gpgsigning.html>
[check-file-recipients]: <https://security.stackexchange.com/questions/85157/can-i-check-who-can-decrypt-my-gpg-message-after-i-encrypt-it>
[gpg2-man]: <https://www.linux.org/docs/man1/gpg2.html>
[Creating gpg key guide]: <https://blog.tinned-software.net/create-gnupg-key-with-sub-keys-to-sign-encrypt-authenticate/>
[debian subkeys]: <https://wiki.debian.org/Subkeys>


[OpenPGPkeyserver]: <http://keys.gnupg.net/>
[MIT PGP Public Key Server]: <https://pgp.mit.edu/>
[Ubuntu PGP Key Server]: <https://keyserver.ubuntu.com/>