
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BillOfMaterials           = Parameters.BillOfMaterials;
	CountPlan         = Parameters.CountPlan;
	TechProcessParameters   = Parameters.TechProcessParameters;
	
	TechnologicalProcess = TechProcessParameters.TechnologicalProcess; // CatalogRef.TechnologicalProcesses
	
	MainProductData = Catalogs.BillsOfMaterials.MainProductSpecificationData(
		BillOfMaterials);
	
	CoefficientData = DataProcessors.ProductionProcessEditor.DataOfTechnologicalProcessCoefficient(
		TechnologicalProcess, MainProductData);
		
	NumeratorFactor   = CoefficientData.Numerator;
	FactorDenominator = CoefficientData.Denominator;
	
	UnitOfMeasurePresentation = String(MainProductData.UnitOfMeasure);
	Items.TheSceneryIsPlanned.Title = UnitOfMeasurePresentation;
	Items.DecorationFactor2.Title  = UnitOfMeasurePresentation;
	
	Items.TextDecoration.Title = StrTemplate(NStr("vi = 'Sẽ thực hiện thay thế sang %1: %2.';
													|ru = 'Будет выполнена замена на %1: %2.';
													|en = 'Will be replaced with %1: %2.'; fa = 'Will be replaced with %1: %2.';
													|it = 'Will be replaced with %1: %2.';
													|pl = 'Will be replaced with %1: %2.';
													|tr = '%1: %2 kapsamında değişiklik yapılacaktır.'"),
		?(TypeOf(TechnologicalProcess) = Type("CatalogRef.RouteSheets"),
			NStr("vi = 'Sơ đồ quy trình';
				|ru = 'маршрутную карту';
				|en = 'route sheet'; fa = 'route sheet';
				|it = 'route sheet';
				|pl = 'route sheet';
				|tr = 'rotayı'"),
			NStr("vi = 'Quy trình công nghệ';
				|ru = 'технологический процесс';
				|en = 'technological process'; fa = 'technological process';
				|it = 'technological process';
				|pl = 'technological process';
				|tr = 'teknolojik süreç'")),
		TechnologicalProcess);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ContinueButton(Command)
	
	If CheckFilling() Then
		
		TechProcessParameters.TechnologicalProcessFactor = CountPlan * NumeratorFactor / FactorDenominator;
		
		Close(TechProcessParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelButton(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion
