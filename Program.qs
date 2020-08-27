namespace FactorIT {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Oracles;
    open Microsoft.Quantum.Characterization;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Random;
    

    // @EntryPoint()
    // operation SayHello() : Unit {
    //     Message("Hello quantum world!");
    // }
    operation FactorSemiPrime(number : Int,useRobustPhaseEstimation: Bool): (Int,Int){
        if(number % 2 == 0){
            Message("WTF dude ? , Give me Prime Numbers only" );
            return(number/2,2);
        }
        mutable FoundFactor = false;
        mutable factor = (1,1);
        
        repeat{
            let Generator = DrawRandomInt(1,number - 2) + 1;

            if (IsCoprimeI(Generator,number)){
                Message($"Estimating period if {Generator}");
                let Period = EstimatePeriod(Generator,number,useRobustPhaseEstimation);
                Message($"Estimated Period is : {Period}");
                set(FoundFactor,factor) = MaybeFactorsFromPeriod(number,Generator,Period);
            }
            else{
                let gcd = GreatestCommonDivisorI(number,Generator);
                Message($"We are guessing the Prime of {number} to be {gcd} , bcuz why not ?");
                set FoundFactor = true;
                set factor = (gcd,number/gcd);
            }
        }
        until(FoundFactor)
        fixup{
            Message("=( , plz wait , trying again");
        }
        return factor;
    }
    operation ApplyOrderFindingOracle(Generator : Int,modulus : Int,power : Int, target : Qubit[]) : Unit
    is Adj + Ctl {
        Fact(IsCoprimeI(Generator,modulus),"`Generator` and `modulus` must be coprime");
        MultiplyByModularInteger(ExpModI(Generator,power,modulus),modulus,LittleEndian(target));
    }
    operation EstimatePeriod(
        Generator:Int,modulus:Int,useRobustPhaseEstimation:Bool
    ):Int{
        Fact(IsCoprimeI(Generator,modulus),"`Generator` and `modulus` must be Coprime");
        mutable result = 1;
        let bitsize = BitSizeI(modulus);
        let bitPrecision = 2*bitsize+1;
        mutable frequencyEstimate = 0;

        repeat{
            set frequencyEstimate = EstimateFrequency(Generator,modulus,useRobustPhaseEstimation,bitsize);
            if (frequencyEstimate != 0){
                set result = PeriodFromFrequency(modulus,frequencyEstimate,bitPrecision,result);

            }
            else{
                Message("The frequency was 0 , Trying again");
            }
            
        }
        until(ExpModI(Generator,result,modulus) == 1)
        fixup{
            Message("The estimated period failed , trying again =(");
        }
        return result; 
    }
    operation EstimateFrequency(Generator : Int,modulus:Int,useRobustPhaseEstimation : Bool,bitsize:Int) :Int
    {
        mutable frequencyEstimate = 0;
        let bitPrecision = 2*bitsize+1;
        using(eigenstateRegister = Qubit[bitsize]){
            let eigenstateRegisterLE = LittleEndian(eigenstateRegister);
            ApplyXorInPlace(1,eigenstateRegisterLE);
            let oracle = DiscreteOracle(ApplyOrderFindingOracle(Generator,modulus,_,_));
            if (useRobustPhaseEstimation){
                let phase = RobustPhaseEstimation(bitPrecision,oracle,eigenstateRegisterLE!);
                set frequencyEstimate = Round((phase*IntAsDouble(2^bitPrecision))/2.0/PI());
            }
            else{
                using (register = Qubit[bitPrecision]){
                    let frequencyEstimateNumerator = LittleEndian(register);
                    QuantumPhaseEstimation(
                        oracle,eigenstateRegisterLE!,LittleEndianAsBigEndian(frequencyEstimateNumerator)
                    );
                    set frequencyEstimate = MeasureInteger(frequencyEstimateNumerator);
                }
            }
            ResetAll(eigenstateRegister);
        }
        return frequencyEstimate;
    }
    function PeriodFromFrequency(
        modulus:Int,
        frequencyEstimate:Int,
        bitPrecision:Int,
        currentDivisor:Int
    ):Int{
        let (numerator ,Period) = (ContinuedFractionConvergentI(Fraction(frequencyEstimate,2^bitPrecision),modulus))!;
        let (numeratorABS,PeriodABS) = (AbsI(numerator),AbsI(Period));
        return (PeriodABS*currentDivisor)/GreatestCommonDivisorI(currentDivisor,PeriodABS);
    }
    function MaybeFactorsFromPeriod(modulus:Int,Generator:Int,period : Int) : (Bool,(Int,Int)) {
        if (period % 2 == 0){
            let halfPower = ExpModI(Generator,period/2,modulus);
            if(halfPower !=modulus-1){
                let factor = MaxI(
                    GreatestCommonDivisorI(halfPower - 1,modulus),
                    GreatestCommonDivisorI(halfPower + 1,modulus)
                );
                return (true,(factor,modulus/factor));

            }
            else{
                return (false,(1,1));
            }
        }
        else{
            Message("Estimated Perioud is odd , trying again");
            return (false,(1,1));
        }
    }
}
