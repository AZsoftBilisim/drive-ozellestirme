#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Writes data to a register.
//
// Parameters:
//  AdjustingEntries	 - ValueTable					 - data to be written.
//  ProductionPlan - DocumentRef.ProductionPlan	 - the document that the adjustments relate to.
//  Replace		 - Boolean							 - the mode of replacement of existing records
//
Procedure RecordAdjustments(AdjustingEntries, ProductionPlan, Replace = False) Export
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(AdjustingEntries) Then
		Return;
	EndIf;
	
	If Not Replace Then
		
		If AdjustingEntries.Count() > 10 Then
			
			Query = New Query(
			"SELECT
			|	CancelProductionPlanAdjustingEntries.*
			|FROM
			|	InformationRegister.CancelProductionPlanAdjustingEntries AS CancelProductionPlanAdjustingEntries
			|WHERE
			|	CancelProductionPlanAdjustingEntries.ProductionPlan = &ProductionPlan
			|");
			Query.SetParameter("ProductionPlan", ProductionPlan);
			
			AllAdjustments = Query.Execute().Unload();
			
			If AllAdjustments.Count() = 0 Then
				
				AllAdjustments = AdjustingEntries;
				
			Else
				
				TheStructureOfTheSearch = New Structure(StrConcat(MeasurementList(), ","));
				
				For Each String In AdjustingEntries Do
					
					FillPropertyValues(TheStructureOfTheSearch, String);
					FoundRows = AllAdjustments.FindRows(TheStructureOfTheSearch);
					
					If FoundRows.Count() = 0 Then
						FillPropertyValues(AllAdjustments.Add(), String);
					Else
						FillPropertyValues(FoundRows[0], String);
					EndIf;
					
				EndDo;
				
			EndIf;
			
			RecordSet = InformationRegisters.CancelProductionPlanAdjustingEntries.CreateRecordSet();
			RecordSet.Filter.ProductionPlan.Set(ProductionPlan);
			RecordSet.Load(AllAdjustments);
			RecordSet.Write(True);
			
		Else
			
			MeasurementList = MeasurementList();
			
			For Each String In AdjustingEntries Do
				
				RecordSet = InformationRegisters.CancelProductionPlanAdjustingEntries.CreateRecordSet();
				
				For Each FieldName In MeasurementList Do
					RecordSet.Filter[FieldName].Use = True;
					RecordSet.Filter[FieldName].ComparisonType  = ComparisonType.Equal;
					RecordSet.Filter[FieldName].Value      = String[FieldName];
				EndDo;
				
				RecordSet.Read();
				
				If RecordSet.Count() = 0 Then
					FillPropertyValues(RecordSet.Add(), String);
				Else
					FillPropertyValues(RecordSet[0], String);
				EndIf;
				
				RecordSet.Write(True);
				
			EndDo;
			
		EndIf;
		
	Else
		
		RecordSet = InformationRegisters.CancelProductionPlanAdjustingEntries.CreateRecordSet();
		RecordSet.Filter.ProductionPlan.Set(ProductionPlan);
		RecordSet.Load(AdjustingEntries);
		RecordSet.Write(True);
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Clears data in the register.
//
// Parameters:
//  ProductionPlan - DocumentRef.ProductionPlan - the document that the adjustments relate to.
//
Procedure ClearAdjustments(ProductionPlan) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.CancelProductionPlanAdjustingEntries AS Table
	|WHERE
	|	Table.ProductionPlan = &ProductionPlan
	|");
	Query.SetParameter("ProductionPlan", ProductionPlan);
	
	If Query.Execute().IsEmpty() Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.CancelProductionPlanAdjustingEntries.CreateRecordSet();
	RecordSet.Filter.ProductionPlan.Set(ProductionPlan);
	RecordSet.Write();
	
	SetPrivilegedMode(False);
	
EndProcedure

// Checks for canceled manual adjustments to the production plan.
//
// Parameters:
//  ProductionPlan - DocumentRef.ProductionPlan - document to check.
// 
// Returns:
//  Boolean - True if there are canceled adjustments according to the production plan.
//
Function ThereAreUndoneAdjustments(ProductionPlan) Export
	
	Query = New Query(
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.CancelProductionPlanAdjustingEntries AS Table
	|WHERE
	|	Table.ProductionPlan = &ProductionPlan
	|");
	Query.SetParameter("ProductionPlan", ProductionPlan);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

#EndRegion

#Region Private

Function MeasurementList()
	
	MeasurementList = New Array();
	
	For Each Field In Metadata.InformationRegisters.CancelProductionPlanAdjustingEntries.Dimensions Do
		MeasurementList.Add(Field.Name);
	EndDo;
	
	Return MeasurementList;
	
EndFunction

#EndRegion

#EndIf