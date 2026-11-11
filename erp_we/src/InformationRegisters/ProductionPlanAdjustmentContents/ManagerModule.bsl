#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a task to the queue to adjust the production plan for semi-finished products.
//
// Parameters:
//  ProductionPlan - DocumentRef.ProductionPlan	 - document being processed
//  ListOfAdjustments - ValueTable				 - list of adjustments
//
Procedure AddToQueue(ProductionPlan, ListOfAdjustments) Export
	
	Set = InformationRegisters.ProductionPlanAdjustmentContents.CreateRecordSet();
	Set.Filter.ProductionPlan.Set(ProductionPlan);
	
	SetPrivilegedMode(True);
	
	For Each String In ListOfAdjustments Do
		
		Set.Filter.Products.Set(String.Products);
		Set.Filter.Characteristic.Set(String.Characteristic);
		Set.Filter.Purpose.Set(String.Purpose);
		Set.Filter.ProductionIssueDateOfIntermediateProducts.Set(String.ProductionIssueDateOfIntermediateProducts);
		
		NewRecord = Set.Add();
		FillPropertyValues(NewRecord, String);
		
		Set.Write(True);
		
		Set.Clear();
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Clears the queue adjustments to the production plan.
//
// Parameters:
//  ProductionPlan - DocumentRef.ProductionPlan	 - document being processed
//
Procedure ClearQueue(ProductionPlan) Export
	
	Set = InformationRegisters.ProductionPlanAdjustmentContents.CreateRecordSet();
	Set.Filter.ProductionPlan.Set(ProductionPlan);
	
	SetPrivilegedMode(True);
	Set.Write(True);
	SetPrivilegedMode(False);
	
EndProcedure

// Clears the queue adjustments to the production plan.
//
// Parameters:
//  ProductionPlan	 - DocumentRef.ProductionPlan	 - document being processed
//  ListOfAdjustments	 - Array, ValueTable			 - list of adjustments
//
Procedure MarkCompletion(ProductionPlan, ListOfAdjustments) Export
	
	If Not ValueIsFilled(ListOfAdjustments) Then
		Return;
	EndIf;
	
	Set = InformationRegisters.ProductionPlanAdjustmentContents.CreateRecordSet();
	Set.Filter.ProductionPlan.Set(ProductionPlan);
	
	SetPrivilegedMode(True);
	For Each String In ListOfAdjustments Do
		
		Set.Filter.Products.Set(String.Products);
		Set.Filter.Characteristic.Set(String.Characteristic);
		Set.Filter.Purpose.Set(String.Purpose);
		Set.Filter.ProductionIssueDateOfIntermediateProducts.Set(String.ProductionIssueDateOfIntermediateProducts);
		
		Set.Write(True);
		
	EndDo;
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#EndIf