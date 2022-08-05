import abi from '../utils/DonatePlatform.json';
import { ethers } from "ethers";
import Head from 'next/head'
import Image from 'next/image'
import React, { useEffect, useState } from "react";
import styles from '../styles/Home.module.css'

export default function Home() {
  // Contract Address & ABI
  const contractAddress = "0x076275c76A8AAF6F3130F26Ab5cD432411d8557A";
  const contractABI = abi.abi;

  // Component state
  const [currentAccount, setCurrentAccount] = useState("");
  const [name, setName] = useState("");
  const [message, setMessage] = useState("");
  const [donations, setDonations] = useState([]);

  const onNameChange = (event) => {
    setName(event.target.value);
  }

  const onMessageChange = (event) => {
    setMessage(event.target.value);
  }

  // Wallet connection logic
  const isWalletConnected = async () => {
    try {
      const { ethereum } = window;

      const accounts = await ethereum.request({ method: 'eth_accounts' })
      console.log("accounts: ", accounts);

      if (accounts.length > 0) {
        const account = accounts[0];
        console.log("wallet is connected! " + account);
      } else {
        console.log("make sure MetaMask is connected");
      }
    } catch (error) {
      console.log("error: ", error);
    }
  }

  const connectWallet = async () => {
    try {
      const { ethereum } = window;

      if (!ethereum) {
        console.log("please install MetaMask");
      }

      const accounts = await ethereum.request({
        method: 'eth_requestAccounts'
      });

      setCurrentAccount(accounts[0]);
    } catch (error) {
      console.log(error);
    }
  }

  const donateETH = async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum, "any");
        const signer = provider.getSigner();
        const donatePlatform = new ethers.Contract(
          contractAddress,
          contractABI,
          signer
        );

        console.log("Donating amount..")
        const donationTxn = await donatePlatform.donateETH(
          name ? name : "anon",
          message ? message : "Thank you for your donation!",
          { value: ethers.utils.parseEther("0.001") }
        );

        await donationTxn.wait();

        console.log("mined", donationTxn.hash);

        console.log("donated!");

        // Clear the form fields.
        setName("");
        setMessage("");
      }
    } catch (error) {
      console.log(error);
    }
  };

  // Function to fetch all donations stored on-chain.
  const getDonations = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const donatePlatform = new ethers.Contract(
          contractAddress,
          contractABI,
          signer
        );

        console.log("fetching donations from the blockchain..");
        const donations = await donatePlatform.getDonations();
        console.log("fetched!");
        setDonations(donations);
      } else {
        console.log("Metamask is not connected");
      }

    } catch (error) {
      console.log(error);
    }
  };

  useEffect(() => {
    let donatePlatform;
    isWalletConnected();
    getDonations();

    // Create an event handler function for when someone sends
    // us a new donation.
    const onNewDonation = (from, name, message, timestamp) => {
      console.log("Donations received: ", from, name, message, timestamp);
      setDonations((prevState) => [
        ...prevState,
        {
          address: from,
          name,
          message,
          timestamp: new Date(timestamp * 1000),
        }
      ]);
    };

    const { ethereum } = window;

    // Listen for new donation events.
    if (ethereum) {
      const provider = new ethers.providers.Web3Provider(ethereum, "any");
      const signer = provider.getSigner();
      donatePlatform = new ethers.Contract(
        contractAddress,
        contractABI,
        signer
      );

      donatePlatform.on("NewDonation", onNewDonation);
    }

    return () => {
      if (donatePlatform) {
        donatePlatform.off("NewDonation", onNewDonation);
      }
    }
  }, []);

  return (
    <div className={styles.container}>
      <Head>
        <title>DataLife Fundraiser!</title>
        <meta name="description" content="Donation site" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <h1 className={styles.title}>
          Donate to the DataLife Project!
        </h1>

        {currentAccount ? (
          <div>
            <form>
              <div>
                <label>
                  Name
                </label>
                <br />

                <input
                  id="name"
                  type="text"
                  placeholder="fav ens"
                  onChange={onNameChange}
                />
              </div>
              <br />
              <div>
                <label>
                  Message to DataLife Team
                </label>
                <br />

                <textarea
                  rows={3}
                  placeholder="Awesome donation!"
                  id="message"
                  onChange={onMessageChange}
                  required
                >
                </textarea>
              </div>
              <div>
                <button
                  type="button"
                  onClick={donateETH}
                >
                  Send 1 Donation for 0.001ETH
                </button>
              </div>
            </form>
          </div>
        ) : (
            <button onClick={connectWallet}> Connect your wallet </button>
          )}
      </main>

      {currentAccount && (<h1>Donations received</h1>)}

      {currentAccount && (donations.map((donation, idx) => {
        return (
          <div key={idx} style={{ border: "2px solid", "borderRadius": "5px", padding: "5px", margin: "5px" }}>
            <p style={{ "fontWeight": "bold" }}>"{donation.message}"</p>
            <p>From: {donation.name} at {donation.timestamp.toString()}</p>
          </div>
        )
      }))}

      <footer className={styles.footer}>
        <a
          href="https://alchemy.com/?a=roadtoweb3weektwo"
          target="_blank"
          rel="noopener noreferrer"
        >
          Created by cargonriv.eth with Alchemy's lesson two of "Road to Web3"!
        </a>
      </footer>
    </div>
  )
}
