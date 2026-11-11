#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Query = New Query(
		"SELECT
		|	CASE 
		|		WHEN Operation.ProductionArea <> VALUE(Catalog.ProductionSites.EmptyRef)
		|			THEN Operation.ProductionArea
		|		WHEN Operation.WorkCenter REFS Catalog.WorkCenters
		|			THEN Operation.WorkCenter.ProductionArea
		|		ELSE VALUE(Catalog.ProductionSites.EmptyRef)
		|	END AS ProductionArea,
		|	CASE
		|		WHEN Operation.UnitOfMeasure = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN &DefaultUnitOfOperation
		|		ELSE Operation.UnitOfMeasure.Presentation
		|	END             AS UnitOfMeasurePresentation,
		|
		|	Operation.LongDesc AS LongDesc
		|FROM
		|	Catalog.ManufacturingOperations AS Operation
		|WHERE
		|	Operation.Ref = &Ref");
	Query.SetParameter("Ref", Record.Operation);
	Query.SetParameter("DefaultUnitOfOperation", NStr("vi = 'op.';
														|ru = 'оп.';
														|en = 'op.'; fa = 'عمل.';
														|it = 'op.';
														|pl = 'op.';
														|tr = 'işlem'"));
	
	FillParameters = "ProductionArea, UnitOfMeasurePresentation";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		FillPropertyValues(ThisForm, Selection, FillParameters);
		
		Items.OperationLongDesc.Visible = ValueIsFilled(Selection.LongDesc);
		
	EndIf;
	
	Items.ProductionArea.Visible = ValueIsFilled(ProductionArea);
	TimeTotal = Record.Count * Record.TimePerPiece + Record.SetupTime;
	
	Files = New Array;
	FilesOperations.FillFilesAttachedToObject(Record.Operation, Files);
	Items.AttachedFiles.Visible = Files.Count()>0;
	Items.AttachedFiles.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Bổ sung nguyên vật liệu (%1)';
			|ru = 'Дополнительные материалы (%1)';
			|en = 'Additional materials (%1)'; fa = 'Additional materials (%1)';
			|it = 'Materiali aggiuntivi (%1)';
			|pl = 'Materiały dodatkowe (%1)';
			|tr = 'Ek malzemeler (%1)'"),
		Files.Count());
	
EndProcedure

#EndRegion
