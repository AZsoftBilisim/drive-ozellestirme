
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Products				= Parameters.Products;
	ListOfCCDTypes				= Parameters.ListOfCCDTypes;
	
	Parameters.Property("DocumentTransfers_", TransferSalesDocument);
	Parameters.Filter.Property("CCDNumberType", CCDNumberType);
	
	FilterEnabled = ValueIsFilled(TransferSalesDocument);
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Parameters.Date);
	
	SetSelectionsByParameters();
	
	Items.FilterEnabled.Visible						= FilterEnabled;
	Items.GroupSaleTransferInstrument.Visible	= FilterEnabled;
	Items.CCDNumberType.Visible						= Not ValueIsFilled(CCDNumberType)
															And UseTraceableImportedGoodsAccounting;
	Items.ListComponents.Visible				= UseTraceableImportedGoodsAccounting;
	
	If ValueIsFilled(ListOfCCDTypes)
		And UseTraceableImportedGoodsAccounting Then
		
		Items.CCDNumberType.ListChoiceMode = True;
		
		Items.CCDNumberType.ChoiceList.LoadValues(ListOfCCDTypes.UnloadValues());
		
	EndIf;
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCDFormOfChoice(
		Items,
		"Code",
		ListOfCCDTypes.UnloadValues(),
		CCDNumberType);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CustomizeListComponents();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterEnabledOnChange(Item)
	
	SetSelectionOnTransferSaleDocument();
	
EndProcedure

&AtClient
Procedure CCDNumberTypeOnChange(Item)
	
	SetSelectionByCCDNumberType(List, CCDNumberType, ListOfCCDTypes.UnloadValues());
	CustomizeListComponents();
	
EndProcedure

&AtClient
Procedure CountryOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"OriginCountry",
		OriginCountry,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(OriginCountry));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListNewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If FilterEnabled Then
		FilterEnabled = False;
		
		SetSelectionOnTransferSaleDocument();
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	CustomizeListComponents();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetSelectionsByParameters()
	
	AttributesNames			= "TracedGoods, OriginCountry";
	ProductAttributes	= Common.ObjectAttributesValues(Products, AttributesNames);
	
	If Parameters.Filter.Property("OriginCountry", OriginCountry) Then
		If Not ValueIsFilled(OriginCountry) Then
			Parameters.Filter.Delete("OriginCountry");
			
			OriginCountry = ProductAttributes.OriginCountry;
		EndIf;
		
		SetSelectionByCountryOfOrigin();
		
	ElsIf ValueIsFilled(ProductAttributes.OriginCountry) Then
		OriginCountry = ProductAttributes.OriginCountry;
		
		SetSelectionByCountryOfOrigin();
	EndIf;
	
	If FilterEnabled Then
		SetSelectionOnTransferSaleDocument();
	EndIf;
	
	If UseTraceableImportedGoodsAccounting Then
		If ListOfCCDTypes.Count() = 0
			And Not ValueIsFilled(CCDNumberType)
			And ProductAttributes.TracedGoods <> Undefined Then
			
			If ProductAttributes.TracedGoods Then
				If Not Parameters.CreatingElementOfAnyType Then
					CCDNumberTypes = AccountingForTraceableGoodsClientServerLocalization.CCDNumberTypes(True);
					
					ListOfCCDTypes.LoadValues(CCDNumberTypes);
				EndIf;
			Else
				CCDNumberType = Enums.CCDNumberTypes.CCDNumber;
			EndIf;
		EndIf;
	Else
		CCDNumberType = Enums.CCDNumberTypes.CCDNumber;
	EndIf;
	
	If ValueIsFilled(CCDNumberType)
		Or ValueIsFilled(ListOfCCDTypes) Then
		
		SetSelectionByCCDNumberType(List, CCDNumberType, ListOfCCDTypes.UnloadValues());
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionByCountryOfOrigin()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"OriginCountry",
		OriginCountry,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(OriginCountry));
	
EndProcedure

&AtServer
Procedure SetSelectionOnTransferSaleDocument()
	
	If FilterEnabled Then
		
		QueryTexts			= New Array;
		NestedRequestTexts	= New Array;
		
		QueryText =
		"SELECT
		|	InventoryKinds.CCDNumber AS Ref
		|FROM
		|	Document.CustomerInvoice.InventoryKinds AS InventoryKinds
		|WHERE
		|	InventoryKinds.Ref = &TransferSalesDocument
		|	AND InventoryKinds.ItemsLocationAttributes.Products = &Products
		|
		|UNION ALL
		|
		|SELECT
		|	InventoryKinds.CCDNumber AS Ref
		|FROM
		|	Document.RetailSalesReport.InventoryKinds AS InventoryKinds
		|WHERE
		|	InventoryKinds.Ref = &TransferSalesDocument
		|	AND InventoryKinds.ItemsLocationAttributes.Products = &Products
		|
		|UNION ALL
		|
		|SELECT
		|	InventoryKinds.CCDNumber AS Ref
		|FROM
		|	Document.CustomerInvoiceIntercompany.InventoryKinds AS InventoryKinds
		|WHERE
		|	InventoryKinds.Ref = &TransferSalesDocument
		|	AND InventoryKinds.ItemsLocationAttributes.Products = &Products";
		
		NestedRequestTexts.Add(QueryText);
		
		QueryText =
		"SELECT DISTINCT
		|	NestedQuery.Ref AS Ref
		|FROM
		|	&TheTextOfASubquery AS NestedQuery";
		
		QueryText =StrReplace(QueryText,
									"&TheTextOfASubquery",
									"(" + StrConcat(NestedRequestTexts, TMCommonUse.QuerySeparatorInJoin()) + ")");
		
		QueryTexts.Add(QueryText);
		
		Query = New Query;
		Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
		Query.SetParameter("Products",				Products);
		Query.SetParameter("TransferSalesDocument",	TransferSalesDocument);
		
		QueryResult	= Query.Execute();
		SelectionOfCCDNumbers	= QueryResult.Select();
		ListOfCCDNumbers	= New ValueList;
		
		While SelectionOfCCDNumbers.Next() Do
			ListOfCCDNumbers.Add(SelectionOfCCDNumbers.Ref);
		EndDo;
		
		CommonClientServer.SetDynamicListFilterItem(List,
																				"Ref",
																				ListOfCCDNumbers,
																				DataCompositionComparisonType.InList,
																				,
																				True);
		
	Else
		CommonClientServer.SetDynamicListFilterItem(List, "Ref", , , , False);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByCCDNumberType(List, CCDNumberType, ListOfCCDTypes)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"CCDNumberType",
		CCDNumberType,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(CCDNumberType));
		
	If Not ValueIsFilled(CCDNumberType) And ListOfCCDTypes.Count() > 0 Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"CCDNumberType",
			ListOfCCDTypes,
			DataCompositionComparisonType.InList,
			,
			True);
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomizeListComponents()
	
	If Not UseTraceableImportedGoodsAccounting Then
		Items.ListComponents.Visible = False;
	Else
		CurrentData			= Items.List.CurrentData;
		SelectionCCDNumber			= ?(CurrentData = Undefined,
									PredefinedValue("Catalog.CCDNumbers.EmptyRef"),
									CurrentData.Ref);
		NumberOfComponents_ = ?(CurrentData = Undefined, 0, CurrentData.NumberOfComponents_);
		
		CommonClientServer.SetDynamicListFilterItem(
			Components,
			"Ref",
			SelectionCCDNumber,
			DataCompositionComparisonType.Equal,
			,
			NumberOfComponents_ > 0);
		
		Items.ListComponents.Title = ListTitleComponents(NumberOfComponents_);
		Items.ListComponents.Visible = NumberOfComponents_ > 0;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ListTitleComponents(NumberOfComponents_)
	
	ListTitle = NStr("vi = 'Thành phần chi tiết';
					|ru = 'Комплектующие';
					|en = 'Components'; fa = 'اجزا';
					|it = 'Componenti';
					|pl = 'Komponenty';
					|tr = 'Bileşenler'");
	
	If NumberOfComponents_ > 0 Then
		ListTitle = NStr("vi = 'Trong thành phần bộ đóng gói có %1 số đăng ký lô hàng';
						|ru = 'В состав комплекта входит %1 РНПТ';
						|en = 'The kit contains RNPT %1'; fa = 'The kit contains RNPT %1';
						|it = 'Il set include %1 numero di registrazione lotto';
						|pl = 'Do składu zestawu wchodzi %1 Numer rejestracyjny partii towaru';
						|tr = 'RNTP Numarası %1 set içeriğine dahildir'");
		ListTitle = StrTemplate(ListTitle, NumberOfComponents_);
	EndIf;
	
	Return ListTitle;
	
EndFunction

#EndRegion
