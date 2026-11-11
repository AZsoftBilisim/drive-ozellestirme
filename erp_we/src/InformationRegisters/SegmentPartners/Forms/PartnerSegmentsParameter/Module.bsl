
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Not Parameters.Property("Partner") Then
		Return;
	EndIf;
	
	DoNotGenerateDynamicSegments = True;
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		Title = NStr("vi = 'Phân khúc đối tác';
					|ru = 'Сегменты контрагента';
					|en = 'Counterparty segments'; fa = 'Counterparty segments';
					|it = 'Segmenti del contraente';
					|pl = 'Segmenty kontrahenta';
					|tr = 'Cari hesap segmentleri'");
	EndIf;
	
	Partner = Parameters.Partner;
	PartnerName = Common.ObjectAttributeValue(Partner, "Description");
	Title = Title + " (" + PartnerName + ")";
	
	HasEditPermission = SegmentsServer.YouHaveRightToChangeCompositionOfSegments("Partners");
	ArrayOfDependentProps = New Array;
	ArrayOfDependentProps.Add("IncludeInSegment");
	ArrayOfDependentProps.Add("RemoveFromTheSegment");
	ArrayOfDependentProps.Add("SegmentsContextMenuIncludeInSegment");
	ArrayOfDependentProps.Add("SegmentsContextMenuRemoveFromTheSegment");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfDependentProps, "Visible", HasEditPermission);
	
	FillInSegmentTable("Manual_");
	
EndProcedure 

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesSegmentTypesOnCurrentPageChange(Item, CurrentPage)
	
	If Items.PagesSegmentTypes.CurrentPage = Items.PageUpdatableAndDynamic 
		And (Not ListOfDynamicAndUpdatedSegmentsIsGenerated) Then
		
		FillInSegmentTable("UpdatedAndDynamic");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationDynamicSegmentsAreNotDisplayedURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "DisplayDynamicSegments" Then
		DoNotGenerateDynamicSegments = False;
		FillInSegmentTable("UpdatedAndDynamic");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSegments

&AtClient
Procedure SegmentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.PagesSegmentTypes.CurrentPage = Items.PageUpdatableAndDynamic Then
		CurrentData = Items.UpdatedAndDynamic.CurrentData;
	ElsIf Items.PagesSegmentTypes.CurrentPage = Items.PageGeneratedManually Then
		CurrentData = Items.Segments.CurrentData;
	EndIf;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "SegmentsSegment" Or Field.Name = "UpdatedAndDynamicSegment"  Then
		
		ShowValue(Undefined, CurrentData.Segment);
		
	ElsIf Field.Name = "SegmentsEmployeeResponsible" Or Field.Name = "UpdatedAndDynamicEmployeeResponsible"Then
		
		ShowValue(Undefined, CurrentData.EmployeeResponsible);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IncludeInSegment(Command)
	
	IncludeDeleteInSegmentClient(True);
	
EndProcedure

&AtClient
Procedure RemoveFromTheSegment(Command)
	
	IncludeDeleteInSegmentClient(False);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	If Items.PagesSegmentTypes.CurrentPage = Items.PageGeneratedManually Then
		FillInSegmentTable("Manual_");
	Else
		FillInSegmentTable("UpdatedAndDynamic");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInDataForDynamicSegments()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	PartnersSegments.Ref AS Segment,
	|	PartnersSegments.EmployeeResponsible,
	|	PartnersSegments.GenerationMethod
	|FROM
	|	Catalog.PartnersSegments AS PartnersSegments
	|WHERE
	|	(NOT PartnersSegments.IsFolder)
	|	AND (NOT PartnersSegments.DeletionMark)
	|	AND PartnersSegments.GenerationMethod = VALUE(Enum.SegmentGenerationMethods.GenerateDynamically)";
	
	Selection = Query.Execute().Select();
	
	DynamicSegmentQuantity = Selection.Count();
	If DoNotGenerateDynamicSegments Then
		
		If DynamicSegmentQuantity < 5 Then
			
			DoNotGenerateDynamicSegments = False;
			Items.DecorationDynamicSegmentsAreNotDisplayed.Visible = False;
			
		Else
			
			Items.DecorationDynamicSegmentsAreNotDisplayed.Visible = True;
			
		EndIf;
		
	EndIf;
	
	If DoNotGenerateDynamicSegments Then
		ListOfDynamicAndUpdatedSegmentsIsGenerated = True;
		Return;
	EndIf;
	
	While Selection.Next() Do
		
		NewRow = UpdatedAndDynamic.Add();
		FillPropertyValues(NewRow,Selection);
		NewRow.BelongsToSegment = SegmentsServer.BelongsToSegment(Partner, Selection.Segment);
		
	EndDo;
	
	Items.DecorationDynamicSegmentsAreNotDisplayed.Visible = False;
	ListOfDynamicAndUpdatedSegmentsIsGenerated         = True;
	
EndProcedure 

&AtServer
Procedure FillInSegmentTable(TableType)
	
	If TableType = "Manual_" Then
		
		TypeOfFormation = "GenerateManually";
		TableName = "Segments";
		
	ElsIf TableType = "UpdatedAndDynamic" Then
		
		TypeOfFormation = "UpdateRegularly";
		TableName = "UpdatedAndDynamic";
		
	Else
		
		Return;
		
	EndIf;
	
	ThisForm[TableName].Clear();
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	PartnersSegments.Ref AS Segment,
	|	CASE
	|		WHEN SegmentPartners.Partner IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS BelongsToSegment,
	|	PartnersSegments.EmployeeResponsible
	|FROM
	|	Catalog.PartnersSegments AS PartnersSegments
	|		LEFT JOIN InformationRegister.SegmentPartners AS SegmentPartners
	|		ON (SegmentPartners.Segment = PartnersSegments.Ref)
	|			AND (SegmentPartners.Partner = &Partner)
	|WHERE
	|	(NOT PartnersSegments.DeletionMark)
	|	AND (NOT PartnersSegments.IsFolder)
	|	AND PartnersSegments.GenerationMethod = &TypeOfFormation";
	
	Query.SetParameter("TypeOfFormation", Enums.SegmentGenerationMethods[TypeOfFormation]);
	Query.SetParameter("Partner", Partner);
	
	ThisForm[TableName].Load(Query.Execute().Unload());
	
	If TableType = "UpdatedAndDynamic" Then
		
		For Each TableRow In ThisForm[TableName] Do
			TableRow.GenerationMethod = Enums.SegmentGenerationMethods.UpdateRegularly;
		EndDo;
		
	EndIf;
	
	If TableType = "UpdatedAndDynamic" Then
		
		FillInDataForDynamicSegments();
		
	EndIf;
	
EndProcedure // Fill in the table of segments()

&AtClient
Procedure IncludeDeleteInSegmentClient(Enable)
	
	SelectedRows = Items.Segments.SelectedRows;
	
	If SelectedRows = Undefined Then
		Return;
	EndIf;
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ArrayOfSegmentsToProcess = New Array;
	
	For Each SelectedRow In SelectedRows Do
		
		RowData = Items.Segments.RowData(SelectedRow);
		If RowData = Undefined Then
			Continue;
		EndIf;
		
		If RowData.BelongsToSegment = Enable Then
			Continue;
		Else
			ArrayOfSegmentsToProcess.Add(RowData.Segment);
		EndIf;
		
	EndDo;
	
	If ArrayOfSegmentsToProcess.Count() > 0 Then
		
		IncludeDeleteInSegmentServer(ArrayOfSegmentsToProcess, Enable);
		If Enable Then
			Notify("AddingPartnerToSegment");
		Else
			Notify("RemovingPartnerFromSegment");
		EndIf;
	EndIf;
	
EndProcedure // Turn on the Client Segment()

&AtServer
Procedure IncludeDeleteInSegmentServer(ArrayOfSegmentsToProcess,Enable);
	
	For Each ArrayElement In ArrayOfSegmentsToProcess Do
		
		If Enable Then
			
			SegmentsServer.AddPartnerToSegment(ArrayElement,Partner);
			
		Else
			
			SegmentsServer.RemovePartnerFromSegment(ArrayElement,Partner);
			
		EndIf;
		
	EndDo;
	
	FillInSegmentTable("Manual_");
	
EndProcedure // Turn on the Reality of the Segmentserver()

#EndRegion
