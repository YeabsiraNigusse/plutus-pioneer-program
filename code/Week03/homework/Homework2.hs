{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TemplateHaskell       #-}

module Homework2 where

import           Plutus.V1.Ledger.Interval (contains)
import           Plutus.V2.Ledger.Contexts (txSignedBy)
import           Plutus.V2.Ledger.Api (BuiltinData, POSIXTime, PubKeyHash,
                                       ScriptContext (scriptContextTxInfo), Validator,
                                       mkValidatorScript, from,TxInfo (txInfoValidRange))
import           PlutusTx             (applyCode, compile, liftCode)
import           PlutusTx.Prelude     (Bool (False), (.), (&&),traceIfFalse,(+))
import           Utilities            (wrapValidator)

---------------------------------------------------------------------------------------------------
----------------------------------- ON-CHAIN / VALIDATOR ------------------------------------------

{-# INLINABLE mkParameterizedVestingValidator #-}
-- This should validate if the transaction has a signature from the parameterized beneficiary and the deadline has passed.
mkParameterizedVestingValidator :: PubKeyHash -> POSIXTime -> () -> ScriptContext -> Bool
mkParameterizedVestingValidator _beneficiary _deadline () _ctx = 
    traceIfFalse "beneficiary has not signed" signedByBeneficiary &&
    traceIfFalse "the deadline is not passed" deadlinepassed
        where
            info :: TxInfo
            info =  scriptContextTxInfo _ctx

            signedByBeneficiary :: Bool
            signedByBeneficiary = txSignedBy info  _beneficiary

            deadlinepassed :: Bool
            deadlinepassed = contains (from _deadline) (txInfoValidRange info)


{-# INLINABLE  mkWrappedParameterizedVestingValidator #-}
mkWrappedParameterizedVestingValidator :: PubKeyHash -> BuiltinData -> BuiltinData -> BuiltinData -> ()
mkWrappedParameterizedVestingValidator = wrapValidator . mkParameterizedVestingValidator

validator :: PubKeyHash -> Validator
validator beneficiary = mkValidatorScript ($$(compile [|| mkWrappedParameterizedVestingValidator ||]) `applyCode` liftCode beneficiary)
