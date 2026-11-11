#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a list of values - histograms
//
// Returns:
//    Array - list of values.
Function Histograms() Export
	
	Result = New Array;
	Result.Add(Column);
	Result.Add(Bar);
	Result.Add(Bar3D);
	Result.Add(NormalizedColumn);
	Result.Add(NormalizedBar);
	Result.Add(NormalizedBar3D);
	Result.Add(NormalizedColumn3D);
	Result.Add(Column3D);
	Result.Add(StackedColumn);
	Result.Add(StackedBar);
	Result.Add(StackedBar3D);
	Result.Add(StackedColumn3D);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf