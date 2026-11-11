
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Filter")
		And Parameters.Filter.Property("Owner") Then
		
		If Not Parameters.Filter.Owner.KeepRecordsByCCD Then
			TitleText = NStr("vi = 'Đối với phần tử: không sử dụng ""%Owner%"" số tờ khai hải quan';
							|ru = 'Для элемента: ""%Owner%"" номера ГТД не используются';
							|en = 'CCD numbers are not used for item: ""%Owner%""'; fa = 'CCD numbers are not used for item: ""%Owner%""';
							|it = 'Per l''elemento: ""%Owner%"" i numeri della polizza doganale di carico non si utilizzano';
							|pl = 'Dla elementu: ""%Owner%"" numery ŁDC nie są używane';
							|tr = '""%Owner%"" öğesi için GKB numarası kullanılmıyor'");
			TitleText = StrReplace(TitleText, "%Owner%", String(Parameters.Filter.Owner));
			
			AutoTitle	= False;
			Title		= TitleText;
			
			Items.List.ReadOnly = True;
		EndIf;
		
	EndIf;
	
	SetSelectionByCCDNumberType(List, CCDNumberType);
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.CCDNumbers);
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Date(1, 1, 1));
	
	Items.FormChangeSelectedItems.Visible					= CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible	= CanBeEdited;
	
	Items.CCDNumberType.Visible			= UseTraceableImportedGoodsAccounting;
	Items.ListComponents.Visible	= UseTraceableImportedGoodsAccounting;
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "Code");
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CustomizeListComponents();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CCDNumberTypeOnChange(Item)
	
	SetSelectionByCCDNumberType(List, CCDNumberType);
	CustomizeListComponents();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	CustomizeListComponents();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetSelectionByCCDNumberType(List, CCDNumberType)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"CCDNumberType",
		CCDNumberType,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(CCDNumberType));
	
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
