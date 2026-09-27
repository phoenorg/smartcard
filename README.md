# Smartcard

**A self-hostable digital business card for conferences, meetups and spontaneous introductions.**

You are at a conference. Someone asks for your details. Your paper business cards are at home, or you chose not to print any. Open Smartcard, show the QR code and share a polished contact card in seconds.

Smartcard is built by [Phoen](https://phoen.org). It is lightweight, mobile-first and designed to run from your own website. Your domain, your card, your link.

[Explore Phoen.org](https://phoen.org) · [Open the source code](https://github.com/phoenorg/smartcard)

## Why Smartcard

- **Conference-ready:** open your card and let the other person scan.
- **Self-hostable:** publish the static files on your own domain or hosting provider.
- **Decentralized by design:** no mandatory account, central directory or hosted profile service.
- **Paper-conscious:** reuse one digital card rather than distributing disposable printed cards.
- **Installable:** add the PWA to a compatible phone for fast access.
- **Immediately useful:** share a URL, show a QR code or export a VCF contact.
- **Lightweight:** plain HTML, CSS and JavaScript, without a front-end framework.
- **Privacy-conscious:** your own card is saved locally in your browser.

## The conference moment

Smartcard is for the moment when you want to exchange details without searching for paper, spelling an email address or asking someone to install an app.

Open the card. Turn your phone. Let them scan. You look prepared, they receive useful contact information, and you avoid another piece of paper that may be lost before the event ends.

## Decentralized and self-hostable

Smartcard is a static web application. It can be deployed on your own domain, subdomain, internal server or static hosting provider. A shared QR code contains the card URL, so it can work from the location you control.

There is no required Smartcard account and no mandatory central directory. The person hosting the application controls its deployment, availability and domain.

> Keep your public deployment URL stable. A QR code remains useful only while its encoded address remains available.

## Features

- Custom digital business card
- Mobile-first animated presentation
- Email, telephone and website actions
- Compact QR preview on the main card
- Full-screen QR presentation
- Shareable card URL
- VCF contact export
- Favorites and scanned-card history
- Installable PWA behavior
- Offline asset cache
- Visible Phoen.org and source-code access
- Static self-hosting

## Quick start

Serve the project from a local web server. Service workers require HTTPS or `localhost` in most browsers.

```bash
python3 -m http.server 8080
```

Open `http://localhost:8080`.

## Deploy on your own website

Upload the project files to a public directory, preserve their relative paths and enable HTTPS.

```text
https://card.example.org/
https://example.org/card/
```

Create your card after deployment, then scan it from a second device before using it at an event.

## Project files

```text
index.html               Application structure and branded content
styles.css               Responsive visual system
app.js                   Card creation, sharing, contacts and history
qr.bundle.js             Local QR generation library
manifest.webmanifest     PWA metadata
sw.js                    Offline cache and service worker
logo.svg                 Smartcard icon
context.md               Durable project rules
```

## Source link

The interface points to:

```text
https://github.com/phoenorg/smartcard
```

Update that URL in `index.html` if the final repository address differs.

## About Phoen

Smartcard is a [Phoen](https://phoen.org) project. Phoen creates open, lightweight and privacy-conscious digital products. The app links to Phoen from the welcome screen, shared-card experience, QR view and settings without blocking the contact flow.

## Sustainability note

Smartcard can reduce reliance on disposable business cards. Digital services still use devices, networks and hosting infrastructure, so the project favors a small framework-free footprint, reusable cards and long-lived self-hosted URLs rather than claiming that digital sharing has no impact.

## Contributing

Issues and pull requests are welcome. Keep contributions lightweight, mobile-first, accessible and compatible with self-hosting. Avoid mandatory third-party services when a local or static approach is available.

## License

Add a `LICENSE` file before publishing if you want to define reuse and contribution terms. Until a license is included, standard copyright rules apply.
