#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns enumeration values corresponding to the intended use.
//
// Parameters:
//   PurposeUseKey - String - purpose of using reserves
//
// Returns:
//   Array - array elements are enumerationslink.Types of reservesreferences
//
Function TypesOfReservesByPurpose(PurposeUseKey) Export
	
	If PurposeUseKey = "FutureExpenseCommitments" Then
		TypesOfReserves = FutureExpenseCommitments();
	ElsIf PurposeUseKey = "WageReserves" Then
		TypesOfReserves = WageReserves();
	Else
		TypesOfReserves = AllTypesOfReserves();
	EndIf;
	
	Return TypesOfReserves;
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not Parameters.Property("PurposeUseKey") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If Parameters.PurposeUseKey = "WageReserves" Then
		ChoiceList = WageReserves();
	Else
		ChoiceList = FutureExpenseCommitments();
	EndIf;
	
	ChoiceData.LoadValues(ChoiceList);
	
EndProcedure

#EndRegion

#Region Private

Function AllTypesOfReserves()
	
	Query = New Query;
	Query.Text = "SELECT Ref FROM Enum.TypesOfProvisionsAndContingentLiabilities";
	Result = Query.Execute().Unload();
	
	Return Result.UnloadColumn("Ref");
	
EndFunction

Function FutureExpenseCommitments()

	TypesOfReserves = New Array;
	
	TypesOfReserves.Add(ResidualLiabilities);
	
	If Not Common.SubsystemExists("SalaryCadresApplications") Then
		TypesOfReserves.Add(Payroll);
	EndIf;
	
	TypesOfReserves.Add(OtherItems);
	
	Return TypesOfReserves;

EndFunction

Function WageReserves()

	TypesOfReserves = New Array;
	
	TypesOfReserves.Add(Payroll);
	
	Return TypesOfReserves;

EndFunction

#EndRegion

#EndIf
