# LinkForge

LinkForge is an advanced NFT platform that empowers creators to distribute NFTs via unique, single-use links, thereby ensuring secure and gasless transactions.

- Zero Coding Requirements: We've made deployment easy for creators, completely eliminating the need for coding when setting up a contract.
- Frictionless Onboarding: With our unique gasless minting technology embedded in link delivery, we offer a seamless onboarding experience. Creators can - distribute NFTs even before receivers have set up a wallet!
- IPFS-Hosted Metadata: We prioritize durability and preservation by pinning all metadata to IPFS, an advanced, decentralized file storage system. This assures longevity and persistent accessibility of your assets.
- Secure, Trustless NFT Delivery: Our cutting-edge technology facilitates the distribution of NFTs via one-of-a-kind links. This pioneering, trustless method promotes secure transmission and rightful ownership of digital assets, fostering greater trust and wider participation in the NFT ecosystem.
- Trusted by the Best: LinkForge is trusted and incorporated by top-tier NFT projects, including renowned names like Pudgy Penguins and Elysium System


## Introduction
In the swiftly evolving blockchain landscape, Non-Fungible Tokens (NFTs) have emerged as a prominent means to represent ownership of distinct digital assets. However, the secure and efficient distribution of NFTs via off-chain channels, such as email, QR codes, and NFC Tags, has posed significant challenges for creators. To address this, Ctor Lab is excited to introduce LinkForge, an innovative protocol that empowers creators to distribute NFTs and Fungible Tokens (FTs) through unique, single-use links, guaranteeing a secure and streamlined distribution process.

## The Problem
Distributing NFTs and FTs currently necessitates user interaction with smart contracts, which can be a complex and bewildering process. Despite the assistance of wallet services like Magic and Torus, this complexity remains a significant barrier to mass adoption, particularly for products that blend digital and physical experiences. For example, limited-edition sneakers with integrated NFTs that authenticate ownership and rarity.

Existing solutions typically depend on centralized servers to validate off-chain data and initiate on-chain transactions, creating a single point of failure in terms of security and reliability. Creators are left with the choice of either managing centralized servers themselves or placing their trust in operators, leading to a reliance on centralized servers.

At Ctor Lab, we envision a different approach. Our aim is to develop a decentralized, trustless protocol that does not sacrifice convenience. We strive for an exceptional user experience that surpasses existing solutions. To accomplish this, we have identified several criteria for an ideal solution:

**Frictionless Onboarding**: Users should not be required to install any apps on their devices. Claiming NFTs should be possible through a browser alone.

**Tamper-proof & Trustless Security**: The protocol should be mathematically guaranteed to ensure that only creators can distribute NFTs, without even relying on us.

**Gasless Minting without Interaction**: Ideally, users should not need their wallets to sign messages and transactions. By eliminating this requirement, users can avoid risking their assets, thus enhancing overall security.

We believe we have discovered the ideal solution.

## Introducing LinkForge
LinkForge, developed by Ctor Lab, offers creators a secure method to distribute tokens using unique single-use links. These links can be shared online or incorporated into physical items like NFC tags and QR codes, providing a seamless and versatile distribution experience for both digital and physical assets.

### How it works
When creators begin using the protocol, they create a certificate authority (CA), a secret known only to them, and commit it to the blockchain for future use. The most straightforward method for generating the CA is by deriving it from the creator's wallet.

Each time a creator generates a unique link for distributing an NFT, a new secret is randomly created and incorporated into the URL of the unique link. To ensure tamper-proof verifiable authenticity, the CA is used to cryptographically sign the secret.

When a user claims a token through the unique link, the secret is utilized to generate proof of ownership for the wallet where the user wishes to deposit the NFTs, rather than directly revealing the secret. The smart contract then verifies the proof and mints the NFTs for the user. In the future, we are considering incorporating zero-knowledge proof for applications that demand enhanced privacy.

It is important to note that both the secret and proof generation occur on the user's device. The secret is never transmitted from the browser to our server. Only the proof of ownership is submitted to the smart contract. As the proof is tied to the user and cannot be misused by others, it can be submitted by anyone.

In fact, we have integrated Gelato Network, one of the most robust relayer networks, to handle on-chain proof submission. This not only eliminates the need for a server to trigger on-chain interactions during the claiming process but also ensures maximum reliability for LinkForge.

LinkForge is highly versatile and modular, being token format agnostic and capable of delivering digital assets beyond NFTs, such as ERC20 tokens.

### Application Ideas
Here are a few application ideas we have come up with, although we are confident that you will discover even more creative use cases:

**Email Delivery**: Distribute NFTs via email with LinkForge, offering a seamless user experience without the need for a crypto wallet. LinkForge's unique approach allows easy integration into existing e-commerce environments, providing a streamlined experience. Most importantly, users will not need to have prior knowledge of cryptocurrencies or wallets.

**Phygital**: Combine NFTs with physical merchandise using QR codes or NFC tags to create engaging experiences for users, merging the digital and physical realms.

**Proof of Attendance**: At in-person events, employ LinkForge to distribute unique links that provide a secure method for distributing tokens exclusively to attendees, offering a digital memento or reward for participation.

**Collectibles**: LinkForge, by eliminating the need for centralized servers, serves as an ideal choice for collectibles. The decentralized and secure nature of the protocol ensures the long-term validity of the link, preserving the collectible's value over time.

## Case Study: PenguPin from Pudgy Penguin
Pudgy Penguin, a pioneering NFT project, has embraced LinkForge technology by integrating it into their soulbound collection, PenguPin. PenguPins enable users to showcase their impact and engagement within the community.

Thanks to LinkForge integration, Pudgy Penguin can now efficiently distribute PenguPins both online and at real-life events on a large scale. Furthermore, LinkForge's unique technology eliminates the need for NFT claimants to connect their wallets to sign transactions, ensuring that the community can safely claim PenguPins without risking their assets. This user-friendly approach aligns perfectly with Pudgy Penguin's goal of achieving mass adoption.

At the NFT NYC event hosted by Pudgy Penguin, attendees were first introduced to LinkForge-powered PenguPins as part of the launch of the Pudgy Penguin plushy toys. Unique links, accessible through QR codes attached to the plushy toys, were provided to the event participants, serving as a digital keepsake to celebrate their early access and engagement with the toys.
