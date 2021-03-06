WALLET_PEM="${PROJECT}/../testnet/wallets/users/mike.pem"
ADDRESS=$(erdpy data load --key=address-devnet)
DEPLOY_TRANSACTION=$(erdpy data load --key=deployTransaction-devnet)
DEPLOY_GAS="80000000"
PROXY="http://localhost:7950"
CHAIN_ID=local-testnet

deploy() {
  erdpy --verbose contract deploy --project=${PROJECT} --recall-nonce --pem=${WALLET_PEM} --metadata-not-upgradeable \
        --gas-limit=1400000000 --outfile="deploy-devnet.interaction.json" --send --proxy=${PROXY} --chain=${CHAIN_ID} || return

  TRANSACTION=$(erdpy data parse --file="deploy-devnet.interaction.json" --expression="data['emitted_tx']['hash']")
  ADDRESS=$(erdpy data parse --file="deploy-devnet.interaction.json" --expression="data['emitted_tx']['address']")

  erdpy data store --key=address-devnet --value=${ADDRESS}
  erdpy data store --key=deployTransaction-devnet --value=${TRANSACTION}

  echo "Smart contract address: ${ADDRESS}"
}

checkDeployment() {
  erdpy tx get --hash=$DEPLOY_TRANSACTION --omit-fields="['data', 'signature']"
  erdpy account get --address=$ADDRESS --omit-fields="['code']"
}

deposit() {
  erdpy --verbose contract call ${ADDRESS} --recall-nonce --pem=${WALLET_PEM} \
        --gas-limit=31029682 --value=50000 --function=deposit --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

deployMigrationContract() {
  CODE_HEX="0x$(xxd -p ./output/payment_account.wasm | tr -d '\n')"

  erdpy --verbose contract call ${ADDRESS} --recall-nonce --pem=${WALLET_PEM} \
        --gas-limit=303726800 --arguments ${CODE_HEX} --function=deployContract --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

migrate() {
  erdpy --verbose contract call ${ADDRESS} --recall-nonce --pem=${WALLET_PEM} \
        --gas-limit=303726800 --function=migrate --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

getBalance() {
  erdpy --verbose account get --address ${ADDRESS} --balance --proxy=${PROXY}
}

migrated() {
  erdpy --verbose contract query ${ADDRESS} --function=migratedTo --proxy=${PROXY}
}
