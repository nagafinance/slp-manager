import './App.css';
import React from "react";
import Axios from "axios";
import { useState, useEffect } from 'react'
import Web3 from 'web3';
import abi from './contractABI';
import { makeStyles } from "@material-ui/core/styles"
import {
    BrowserRouter as Router,
    Switch,
    Route,
    Link
  } from "react-router-dom";
import {
  Drawer, List, ListItem,
  ListItemIcon, ListItemText,
  Container, Typography,
} from "@material-ui/core";
import { grey } from '@mui/material/colors';
import HomeIcon from '@mui/icons-material/Home';
import InfoIcon from '@mui/icons-material/Info';
import AddIcon from '@mui/icons-material/Add';
import ChangeCircleIcon from '@mui/icons-material/ChangeCircle';
import PersonRemoveIcon from '@mui/icons-material/PersonRemove';
import PercentIcon from '@mui/icons-material/Percent';
import PaymentsIcon from '@mui/icons-material/Payments';
import TransitEnterexitIcon from '@mui/icons-material/TransitEnterexit';


const useStyles = makeStyles((theme) => ({
  drawerPaper: { width: 'inherit'},
  link: {
    textDecoration: 'none',
    color: theme.palette.text.primary
  }
}))


function App() {
    const classes = useStyles();

  const [roninAddress, setRoninAddress] = useState('')
  const [playerAddress, setPlayerAddress] = useState('')
  const [percentShare, setPercentShare] = useState('')
  const [currentAccount, setCurrentAccount] = useState('')
  const [weiAmount, setWeiAmount] = useState('')
  const [scholarUint, setScholarUint] = useState('')
  const [guildMasterAddress, setGuildMasterAddress] = useState('')
  const [balance, setBalance] = useState('')
//   const [totalClaimAble, setTotalClaimAble] = useState('')
  const [axieName, setAxieName] = useState('')
  const [axieSLP, setaxieSLP] = useState('')


  async function loadWeb3() {
    if (window.ethereum) {
        window.web3 = new Web3(window.ethereum);
        window.ethereum.enable();
    }
  }

    //Run once, to get current wallet address/guildMaster
    useEffect(() => {
        getAccounts();
        callGuildMaster();
        callBalance();
        // callClaimableTotal();
        }, [])

    const getAxieAPI = () => {
        Axios.get("https://game-api.axie.technology/api/v1/ronin:" + roninAddress).then(
            (response) => {
                setAxieName(response.data.name);
                setaxieSLP(response.data.total_slp);
            }
        )
    }

    useEffect(() => {
        getAxieAPI();
    }, [])

  async function loadContract() {
      return await new window.web3.eth.Contract(
          abi
          , '0x62d7be6e401E1397ef2b608240637F95dAF50Df7');
  }


  //Function Call
  async function callScholar() {

        await  window.contract.methods.scholarLength().call()
            .then(res => console.log('number of scholar:', res))
            .catch(err => console.log(err))

  }

  async function callPlayerList() {

        await  window.contract.methods.playerList(playerAddress).call()
            .then(res => console.log('PlayerList:', res))
            .catch(err => console.log(err))

  }  

  async function callRoninInfo() {
        await  window.contract.methods.roninInfo(roninAddress).call()
            .then(res => console.log('roninInfo:', res))
            .catch(err => console.log(err))
  }

  async function callScholarInfo() {
        await  window.contract.methods.scholarInfo(roninAddress).call()
            .then(res => console.log('Scholar Info:', res))
            .catch(err => console.log(err))
  }  

  
  //Function Send

  async function addScholar() {
      await  window.contract.methods.addScholar(roninAddress,
      roninAddress, percentShare).send({from: currentAccount})
  }

  async function changePlayer() {
      await  window.contract.methods.changePlayer(roninAddress,
      playerAddress).send({from: currentAccount})
  }

  async function removeOldPlayer() {
      await  window.contract.methods.removeOldPlayer(playerAddress).send({from: currentAccount})
  }

  async function deposit() {
     
      await  window.contract.methods.deposit(weiAmount).send({from: currentAccount})
  }

  async function withdraw() {
   
    await  window.contract.methods.withdraw(weiAmount).send({from: currentAccount})
  }

  async function claim() {
    await  window.contract.methods.claim().send({from: currentAccount})
  }

  async function updatePercentShare() {
      // updateStatus('Updating Percent Share...');
      await  window.contract.methods.updatePercentShare(roninAddress, percentShare).send({from: currentAccount})
  }


  //get wallet account index[0]
  async function getCurrentAccount() {
      const accounts = await window.web3.eth.getAccounts();
      return accounts[0];
  }

  //load smart contract, display 'Ready!' when successfully loaded.
  async function load() {
      await loadWeb3();
      window.contract = await loadContract();

  }


  load();

  async function callBalance() {

        await  window.contract.methods.balance().call()
            .then(res => setBalance(res))
            .catch(err => console.log(err))

  }

//   async function callClaimableTotal() {

//         await  window.contract.methods.claimableTotal().call()
//             .then(res => setTotalClaimAble(res))
//             .catch(err => console.log(err))

//   }

    async function callGuildMaster() {
    await  window.contract.methods.guildMaster().call()
        .then(res => setGuildMasterAddress(res))
        .then(res => console.log(res))
        .catch(err => console.log(err))

    }

  function getAccounts() {
    window.web3.eth.getAccounts((error,result) => {
      result = String(result);
        if (error) {
            console.log(error);
        } else {
            setCurrentAccount(result)
        }
    });
  }


  const roninAddressInnput = <label>
        <input 
            type="text" 
            placeholder= "Ronin Address"
            onChange={(e) => setRoninAddress(e.target.value)}
            value={roninAddress}
        />
        </label>

  const playerAddressInput = <label>
        <input 
            type="text" 
            placeholder= "Player Address"
            onChange={(e) => setPlayerAddress(e.target.value)} 
            value={playerAddress}
        />
        </label>

  const scholarUintInput = <label>
            <input 
                type="text" 
                placeholder= "Scholar index"
                onChange={(e) => setScholarUint(e.target.value)} 
                value={scholarUint}
            />
            </label>

  const  percentShareInput = <label>
            <input 
                type="text" 
                placeholder= "Percent Share"
                onChange={(e) => setPercentShare(e.target.value)} 
                value={percentShare}
            />
            </label>

  const weiAmountInput = <label>
        <input 
        type="text" 
        placeholder= "Wei Amount Deposit"
        onChange={(e) => setWeiAmount(e.target.value)} 
        value={weiAmount}
        />
        <br/>
        </label>

    const weiAmountInputW = <label>
    <input 
    type="text"
    placeholder= "Wei Amount Withdraw"
    onChange={(e) => setWeiAmount(e.target.value)} 
    value={weiAmount}
    />
    </label>

    console.log(roninAddress)


  return (
    <div className="App">
        <Router>
        <div style={{ display: 'flex' }}>
            <Drawer
            style={{ width: '10rem' }}
            variant="persistent"
            anchor="left"
            open={true}
            classes={{ paper: classes.drawerPaper }}
            >
          <List>
            <Link to="/" className={classes.link}>
              <ListItem button>
                <ListItemIcon>
                  <HomeIcon/>
                </ListItemIcon>
                <ListItemText primary={"Home"} />
              </ListItem>
            </Link>
            {(currentAccount === guildMasterAddress) &&
            <Link to="/add-scholar" className={classes.link}>
              <ListItem button>
                <ListItemIcon>
                  <AddIcon />
                </ListItemIcon>
                <ListItemText primary={"Add Scholar"} />
              </ListItem>
            </Link>}
            {(currentAccount === guildMasterAddress) &&
            <Link to="/change-player" className={classes.link}>
              <ListItem button>
                <ListItemIcon>
                  <ChangeCircleIcon />
                </ListItemIcon>
                <ListItemText primary={"Change Player"} />
              </ListItem>
            </Link>}
            {(currentAccount === guildMasterAddress) &&
            <Link to="/remove-player" className={classes.link}>
              <ListItem button>
                <ListItemIcon>
                  <PersonRemoveIcon />
                </ListItemIcon>
                <ListItemText primary={"Remove Player"} />
              </ListItem>
            </Link>}
            {(currentAccount === guildMasterAddress) &&
            <Link to="/change-share-percent" className={classes.link}>
              <ListItem button>
                <ListItemIcon>
                  <PercentIcon />
                </ListItemIcon>
                <ListItemText primary={"Change Share Percent"} />
              </ListItem>
            </Link>}
            {(currentAccount === guildMasterAddress) &&
            <Link to="/deposit" className={classes.link}>
              <ListItem button>
                <ListItemIcon>
                  <PaymentsIcon />
                </ListItemIcon>
                <ListItemText primary={"Deposit"} />
              </ListItem>
            </Link>}

            {(currentAccount === guildMasterAddress) &&
            <Link to="/withdraw" className={classes.link}>
              <ListItem button>
                <ListItemIcon>
                  <TransitEnterexitIcon />
                </ListItemIcon>
                <ListItemText primary={"Withdraw"} />
              </ListItem>
            </Link>}

          </List>
        </Drawer>
        <Switch>
        <div className="interfaceUI">
          <Route exact path="/">
            <Container className="Home-css">
            {(roninAddress !== '') &&
            <React.Fragment>
                In-game Name: {axieName} <br/> 
            </React.Fragment>}

            {(roninAddress !== '') &&
                <React.Fragment>
                Total SLP: {axieSLP} <br/>
            </React.Fragment>}

                Pool Balance: {balance} <br/>
                {/* Claimable Amount: {totalClaimAble} */}
            </Container>
          </Route>
          <Route exact path="/add-scholar">
            {(currentAccount === guildMasterAddress) &&<Container>
                <div className="card">
                    {roninAddressInnput} <br/>
                    {playerAddressInput} <br/>
                    {percentShareInput} <br/>
                    <button className="bn5" onClick={addScholar}>Add Scholar</button>
                </div>
            </Container>}
          </Route>
          <Route exact path="/change-player">
          {(currentAccount === guildMasterAddress) && <Container>
                {roninAddressInnput} <br/>
                {playerAddressInput} <br/>
                <button className="bn5" onClick={changePlayer}>Change Player</button>
            </Container>}
          </Route>
          <Route exact path="/remove-player">
            {(currentAccount === guildMasterAddress) && <Container>
                {playerAddressInput} <br/>
                <button className="bn5" onClick={removeOldPlayer}>Remove Old Player</button>
            </Container>}
          </Route>
          <Route exact path="/change-share-percent">
            {(currentAccount === guildMasterAddress) && <Container>
                {percentShareInput} <br/>
                <button className="bn5" onClick={updatePercentShare}>Update Percent Share</button>
            </Container>}
          </Route>
          <Route exact path="/deposit">
            {(currentAccount === guildMasterAddress) &&<Container>
                {weiAmountInput}
                <button className="bn5" onClick={deposit}>Deposit</button>
                
            </Container>}
          </Route>
          <Route exact path="/withdraw">
            {(currentAccount === guildMasterAddress) &&<Container>
                {weiAmountInputW}
                <button className="bn5" onClick={withdraw}>withdraw</button>
                
            </Container>}
          </Route>

          <Route exact path="/claim">
            {(currentAccount === guildMasterAddress) &&<Container>
                {weiAmountInputW}
                <button className="bn5" onClick={claim}>Claim</button>
                
            </Container>}
          </Route>
        </div>
        </Switch>
      </div>
    </Router>
        
        {/* use or not? */}
        {/* <button onClick={callScholar}>scholarLength</button> */}
        {/* <button onClick={callBalance}>Balance</button>
        <button onClick={callClaimableTotal}>ClaimableTotal</button>
        <button onClick={callRoninInfo}>Ronin Info</button>
        <button onClick={callScholarInfo}>Scholar Info</button> */}

    </div>
  );
}

export default App;
