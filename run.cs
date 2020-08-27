
using System;
using FactorIT;
using Microsoft.Quantum.Simulation.Simulators;
using Microsoft.Quantum.Simulation.Core;

namespace FactorIT
{
    /// <summary>
    /// This is a Console program that runs Shor's algorithm 
    /// on a Quantum Simulator.
    /// This is just a wrapper around Q# Program, not a Real Program 
    /// </summary>
    class Program
    {
        
        static void Main(string[] args)
        {
            long numberToFactor = 49;
            long nTrials = 100;
            bool useRobustPhaseEstimation = true;

            if( args.Length >= 1 )
            {

                Int64.TryParse(args[0], out numberToFactor);
            }

            if (args.Length >= 2 )
            {

                Int64.TryParse(args[1], out nTrials);
            }

            if (args.Length >= 3)
            {

                bool.TryParse(args[2], out useRobustPhaseEstimation);
            }

            for (int i = 0; i < nTrials; ++i)
            {
                try
                {
                    
                    using (QuantumSimulator sim = new QuantumSimulator())
                    {
                        Console.WriteLine($"==========================================");
                        Console.WriteLine($"Factoring {numberToFactor}");

                        (long factor1, long factor2) = 
                            FactorSemiPrime.Run(sim, numberToFactor, useRobustPhaseEstimation).Result;

                        Console.WriteLine($"Factors are {factor1} and {factor2}");
                    }
                }

                catch (AggregateException e )
                {
                    Console.WriteLine($"This run of Shor's algorithm failed:");
                    foreach ( Exception eInner in e.InnerExceptions )
                    {
                        if (eInner is ExecutionFailException failException)
                        {
                            Console.WriteLine($"   {failException.Message}");
                        }
                    }
                }
            }
        }
    }
}