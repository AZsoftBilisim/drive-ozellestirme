
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("FilterStructure1") And Parameters.FilterStructure1.Property("Organization")
		And ValueIsFilled(Parameters.FilterStructure1.Organization) And Not Parameters.Filter.Property("Organization") Then
		// Selection by organization will be established only when there is no selection prescribed through the standard
		// mechanisms of the platform (it is a higher priority)
		CommonClientServer.SetDynamicListFilterItem(List, "Organization",
			Parameters.FilterStructure1.Organization, DataCompositionComparisonType.Equal,, True,
			DataCompositionSettingsItemViewMode.QuickAccess);
	EndIf;
	
	// Selection that sets by default the old behavior for the Form (when sales documents were selected only
	// when they were issued outside the order
	CommonClientServer.SetDynamicListFilterItem(List, "OrderIsNotFilledIn",
		True, DataCompositionComparisonType.Equal, NStr("vi = 'Không hiển thị giao hàng theo đơn';
														|ru = 'Не показывать реализации по заказам';
														|en = 'Do not show sales for orders'; fa = 'Do not show sales for orders';
														|it = 'Do not show sales for orders';
														|pl = 'Do not show sales for orders';
														|tr = 'Siparişlerin gerçekleşmeleri gösterilmesin'"), True,
		DataCompositionSettingsItemViewMode.QuickAccess, "InvoicesByOrderSales");
	
	For Each CustomDocument In ChartsOfCharacteristicTypes.ExpenseItems.IdentifiersOfDocumentsArticlesDistributedForSale() Do
		DocumentTypes.Add(CustomDocument, CustomDocument.Synonym, True);
	EndDo;
	
	List.Parameters.SetParameterValue("RefsTypes", DocumentTypes.UnloadValues());
	TypesOfDocumentsByString = ListOfCustomDocumentsByLine(DocumentTypes);
	
	List.Parameters.SetParameterValue("RefsTypes", SalesServer.TypesOfReferencesImplementationDocuments(True));
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	If FormattedStringURL = "OpenDocumentSelection" Then
		StandardProcessing = False;
		FormParameters = New Structure;
		FormParameters.Insert("RestrictSelectionBySpecifiedValues", True);
		FormParameters.Insert("TypeDescription", New TypeDescription("CatalogRef.MetadataObjectIDs"));
		FormParameters.Insert("ValuesForSelection", DocumentTypes);
		FormParameters.Insert("Presentation", NStr("vi = 'Bộ lọc theo kiểu chứng từ';
													|ru = 'Фильтр по типам документов';
													|en = 'Filter by document types'; fa = 'فیلتر بر اساس انواع سند';
													|it = 'Filter by document types';
													|pl = 'Filter by document types';
													|tr = 'Belge türüne göre filtre'"));
		ListOfMarked = New ValueList;
		ListOfMarked.LoadValues(CommonClientServer.MarkedItems(FormParameters.ValuesForSelection));
		FormParameters.Insert("Marked", ListOfMarked);
		NotificationOfCompletionOfMark = New CallbackDescription("SetList", ThisObject);
		OpenForm("CommonForm.InputValuesInListWithCheckBoxes", FormParameters, ThisObject, UUID,,, NotificationOfCompletionOfMark);
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	TableRow = Items.List.CurrentData;
	NotifyChoice(TableRow.Ref);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectDocument(Command)
	
	TableRow = Items.List.CurrentData;
	If TableRow <> Undefined Then
		NotifyChoice(TableRow.Ref);
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenDocument(Command)
	
	TableRow = Items.List.CurrentData;
	If TableRow <> Undefined Then
		ShowValue(Undefined, TableRow.Ref);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", "Date");
	
EndProcedure

&AtClientAtServerNoContext
Function ListPresentation(ListOfCustomDocuments, NumberOfOutput = 2)
	
	NumberOfSelected = CommonClientServer.MarkedItems(ListOfCustomDocuments).Count();
	If NumberOfSelected = ListOfCustomDocuments.Count() Then
		Return NStr("vi = '< hiển thị tất cả >';
					|ru = '< показаны все >';
					|en = '< shown all >'; fa = '< shown all >';
					|it = '< shown all >';
					|pl = '< shown all >';
					|tr = '< tümü gösteriliyor >'");
	EndIf;
	
	If NumberOfSelected = 0 Then
		Return NStr("vi = '< chưa chọn >';
					|ru = '< не выбраны >';
					|en = '<not selected>'; fa = '<not selected>';
					|it = '<not selected>';
					|pl = '<not selected>';
					|tr = '< seçilmedi >'");
	EndIf;
	
	PresentationsArray = New Array;
	For Each Page1 In ListOfCustomDocuments Do
		If PresentationsArray.Count() = NumberOfOutput Then
			Break;
		EndIf;
		If Page1.Check Then
			PresentationsArray.Add(Page1.Presentation);
		EndIf;
	EndDo;
	
	If PresentationsArray.Count() = 1 Then
		Return PresentationsArray.Get(0);
	EndIf;
	
	If NumberOfSelected > NumberOfOutput Then
		Return StrConcat(PresentationsArray, ", ") + " " + StrTemplate(NStr("vi = 'và còn %1';
																			|ru = 'и еще %1';
																			|en = 'and also %1'; fa = 'and also %1';
																			|it = 'e anche %1';
																			|pl = 'i jeszcze %1';
																			|tr = 've %1 daha'"), NumberOfSelected - NumberOfOutput);
	EndIf;
	
	If PresentationsArray.Count() = NumberOfOutput Then
		Return StrConcat(PresentationsArray, ", ");
	EndIf;
	
EndFunction

&AtClient
Procedure SetList(DocumentsList, AdditionalParameters = Undefined) Export

	If TypeOf(DocumentsList) <> Type("ValueList") Then
		Return;
	EndIf;
	
	DocumentTypes = DocumentsList;
	List.Parameters.SetParameterValue("RefsTypes", CommonClientServer.MarkedItems(DocumentTypes));
	TypesOfDocumentsByString = ListOfCustomDocumentsByLine(DocumentTypes);
	
EndProcedure

&AtClientAtServerNoContext
Function ListOfCustomDocumentsByLine(ListOfCustomDocuments)
	
	ReturnString = New FormattedString(ListPresentation(ListOfCustomDocuments),,,, "OpenDocumentSelection");
	Return ReturnString;
	
EndFunction

#EndRegion
