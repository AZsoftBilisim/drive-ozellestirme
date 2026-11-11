#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	BillOfMaterials           = Parameters.BillOfMaterials;
	TechnologicalProcess = Parameters.TechnologicalProcess;
	CountPlan         = Parameters.CountPlan;
	
	If Not ValueIsFilled(TechnologicalProcess) Then
		Cancel = True;
		Return;
	EndIf;
	
	Fraction = ProductionServer.Fraction(Parameters.TechnologicalProcessFactor, CountPlan);
	ProductionServer.ReduceFraction(Fraction);
	
	NumeratorFactor = Fraction.Numerator;
	FactorDenominator = Fraction.Denominator;
	
	CalculateFactor = Common.ObjectAttributeValue(TechnologicalProcess, "CalculateFactor");
	If CalculateFactor Then
		Items.CalculateCoefficient.Enabled = True;
	EndIf;
	
	MainProductData = Catalogs.BillsOfMaterials.MainProductSpecificationData(
		BillOfMaterials);
	
	Items.TechnologicalProcess.Title = Metadata.FindByType(TypeOf(TechnologicalProcess)).ObjectPresentation;
	UnitOfMeasurePresentation = String(MainProductData.UnitOfMeasure);
	Items.TheSceneryIsPlanned.Title = UnitOfMeasurePresentation;
	Items.DecorationFactor2.Title  = UnitOfMeasurePresentation;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)
	
	If CheckFilling() Then
		Close(CountPlan * NumeratorFactor / FactorDenominator);
	EndIf;
	
EndProcedure

#EndRegion