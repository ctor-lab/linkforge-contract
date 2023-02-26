import { keccak256 } from "@ethersproject/keccak256";
import {Wallet, BytesLike, BigNumberish, Signer, Contract} from "ethers";
import { AbiCoder, defaultAbiCoder, solidityKeccak256 } from "ethers/lib/utils";

type Certificate = {
    chainId: string,
    contract: string,
    deadline: string,
    data: string,
    signerAddress: string,
    signerPrivateKey: string,
    certificate: string
}

export function makeClaimable1155Data(
    tokenId: BigNumberish,
    amount: BigNumberish
): string {
    return defaultAbiCoder.encode(
        ["uint256", "uint256"],
        [tokenId, amount]
    );
}


export async function createCertificate(
    certificateAuthority: Signer,
    chainId: BigNumberish, 
    contract: string, deadline: 
    BigNumberish, data: BytesLike): Promise<Certificate>  {

    const signer = Wallet.createRandom();

    const certificate = await certificateAuthority.signMessage(
        keccak256(
            solidityKeccak256(
                ["address", "uint64", "address", "uint256", "bytes"],
                [signer.address, deadline, contract, chainId, data]
            )
        )
    );
    return {
        chainId: chainId.toString(),
        contract: contract,
        deadline: deadline.toString(),
        data: data.toString(),
        signerAddress: signer.address,
        signerPrivateKey: signer.privateKey,
        certificate: certificate
    };
}
