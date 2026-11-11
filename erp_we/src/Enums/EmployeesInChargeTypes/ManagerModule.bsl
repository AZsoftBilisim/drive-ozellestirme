
#Region EventHandlers

// Handler for the event "processingreceiving the selection Data".
//
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StructuralUnit = Undefined;
	
	If Parameters.Property("StructuralUnit",StructuralUnit) Then
		
		StandardProcessing = False;
		ChoiceData = New ValueList();
		TypeOfStructuralUnit = TypeOf(StructuralUnit);

		If TypeOfStructuralUnit = Type("CatalogRef.Warehouses") Then
			ChoiceData.Add(Enums.EmployeesInChargeTypes.Warehouseman);
		ElsIf TypeOfStructuralUnit = Type("CatalogRef.CashAccounts") Then
			ChoiceData.Add(Enums.EmployeesInChargeTypes.Cashier);
		ElsIf TypeOfStructuralUnit = Type("CatalogRef.Companies") Then
			
			ChoiceData.Add(Enums.EmployeesInChargeTypes.Director);
			ChoiceData.Add(Enums.EmployeesInChargeTypes.ChiefAccountant);
			
		EndIf;
		
	EndIf;

EndProcedure // Processing of the received selection()

#EndRegion
