#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

// Returns an array of IDs of calculation protocols for the specified organizations.
//
// Parameters:
// 	CalculationPeriod - Date - the calculation period
// 	CompanyArray - Array - array of organizations
//
// Returns:
// 	Map - protocol ids
//
Function GetCalculationProtocols(CalculationPeriod, CompanyArray) Export
	
	SetPrivilegedMode(True);
	
	CalculationOptions = New Array;
	
	If CalculationOfCostCached.BatchAccountingVersion22(BegOfMonth(CalculationPeriod)) Then
		CalculationOptions.Add(Enums.LotAndCostCalculationOptions.LotsAndCost);
		CalculationOptions.Add(Enums.LotAndCostCalculationOptions.ActualCostCalculation);
	Else
		CalculationOptions.Add(Enums.LotAndCostCalculationOptions.ActualCostCalculation);
	EndIf;
	
	ProtocolIds = New Map;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	T.UniqueProtocolID AS UniqueProtocolID,
	|	T.Organization AS Organization
	|FROM
	|	InformationRegister.LotAndCostCalculationErrors AS T
	|WHERE
	|	T.Period = &Period
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.CalculationOption IN (&CalculationOptions)
	|
	|ORDER BY
	|	UniqueProtocolID,
	|	Organization
	|TOTALS BY
	|	UniqueProtocolID";
	
	Query.SetParameter("Period", 		   BegOfMonth(CalculationPeriod));
	Query.SetParameter("CompanyArray", TMCommonUseClientServer.Array(CompanyArray));
	Query.SetParameter("CalculationOptions",   CalculationOptions);
	
	SelectingIds = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SelectingIds.Next() Do
		
		ProtocolOrganizations = New Array;
		Selection = SelectingIds.Select();
		
		While Selection.Next() Do
			ProtocolOrganizations.Add(Selection.Organization);
		EndDo;
		
		ProtocolIds.Insert(SelectingIds.UniqueProtocolID, ProtocolOrganizations);
		
	EndDo;
	
	Return ProtocolIds;
	
EndFunction

#EndRegion

#Region Private

#Region InfobaseUpdate

#EndRegion

#EndRegion

#EndIf
