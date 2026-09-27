PHOEN SMARTCARD V6.9 - LARGE CONTACT BUTTONS

Copy contact-buttons-v6-9.css into the project folder.

In index.html, add this line immediately after styles.css:
<link rel="stylesheet" href="contact-buttons-v6-9.css">

In sw.js:
- Add './contact-buttons-v6-9.css' to the cached asset list.
- Change the cache version to phoen-smartcard-v6-9.

The patch greatly enlarges:
- Email, phone and website contact cards
- Their icon areas and typography
- Share, VCF and Show QR controls

Short-screen rules preserve the layout on compact phones.
