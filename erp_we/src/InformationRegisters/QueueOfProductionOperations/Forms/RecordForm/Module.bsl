#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.Operation.Visible                 = ValueIsFilled(Record.Operation);
	Items.ProductionOperation.Visible = ValueIsFilled(Record.ProductionOperation);
	Items.TechnologicalProcess.Visible   = ValueIsFilled(Record.TechnologicalProcess);
	
	Query = New Query("
	|SELECT
	|	CASE
	|		WHEN Operation.WorkCenter REFS Catalog.WorkCenters
	|			THEN Operation.WorkCenter.ProductionArea
	|		ELSE VALUE(Catalog.ProductionSites.EmptyRef)
	|	END                     AS ProductionArea,
	|	Operation.UnitOfMeasure AS UnitOfMeasure,
	|	Operation.LongDesc         AS LongDesc
	|FROM
	|	Catalog.ManufacturingOperations AS Operation
	|WHERE
	|	Operation.Ref = &Operation
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN DocOperation.WorkCenter REFS Catalog.WorkCenters
	|			THEN DocOperation.WorkCenter.ProductionArea
	|		ELSE VALUE(Catalog.ProductionSites.EmptyRef)
	|	END                        AS ProductionArea,
	|	DocOperation.UnitOfMeasure AS UnitOfMeasure,
	|	DocOperation.Comment      AS LongDesc
	|FROM
	|	Document.ProductionOperation2_2 AS DocOperation
	|WHERE
	|	DocOperation.Ref = &ProductionOperation
	|");
	
	Query.SetParameter("Operation", Record.Operation);
	Query.SetParameter("ProductionOperation", Record.ProductionOperation);
	
	Result = Query.Execute().Select();
	
	If Result.Next() Then
		
		ProductionArea = Result.ProductionArea;
		Items.ProductionArea.Visible = ValueIsFilled(ProductionArea);
		
		UnitOfMeasurePresentation = ProductionManagementClientServer.PresentationOfUnitOfOperation(
			Result.UnitOfMeasure,
			,
			True);
		
		LongDesc = Result.LongDesc;
		Items.LongDesc.Visible = ValueIsFilled(LongDesc);
		
	EndIf;
	
	PendingOperationAssignment = 0;
	
	If Record.Scheduled + Record.RepetitionIsRequired > Record.CreatedOn Then
		PendingOperationAssignment = Record.Scheduled + Record.RepetitionIsRequired - Record.CreatedOn;
	EndIf;
	
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

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
EndProcedure

#EndRegion