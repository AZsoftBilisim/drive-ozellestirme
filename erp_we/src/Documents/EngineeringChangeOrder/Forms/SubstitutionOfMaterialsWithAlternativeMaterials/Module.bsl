#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	
	Parameters.Property("GoodsParameters", GoodsParameters);
	Parameters.Property("SubstitutesParameters", SubstitutesParameters);
	Parameters.Property("GeneralParameters", GeneralParameters);
	
	If GeneralParameters.ShowBalance = Undefined Then
		GeneralParameters.ShowBalance = False;
	EndIf;
	
	If GeneralParameters.DetailsMode = Undefined Then
		GeneralParameters.DetailsMode = False;
	EndIf;
	
	If GeneralParameters.DetailsMode Then
		
		SetFormSettingsInDecryptionMode();
		
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	UpdateDataOnForm();
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "CommonForm.FormOfMarkingOfItems" Then
		
		ArrayOfReplacementNumbers = New Array;
		For Each CurReplacement In ValueSelected Do
			If CurReplacement.Check Then
				ArrayOfReplacementNumbers.Add(CurReplacement.Value);	
			EndIf;	
		EndDo;
		
		If ArrayOfReplacementNumbers.Count() > 0 Then
			CancelSelections(ArrayOfReplacementNumbers);
			FillInISServiceAttribute(Substitutes, SubstitutesSelectionMode);
		EndIf;
		
		InstallInscriptionLackOfAnalogues(ThisObject);
		SetAvailabilityOfBalanceDisplayMode(ThisObject);
			
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReplacementSourceOnChange(Item)
	
	FillQuantityToReplace();
	
EndProcedure

&AtClient
Procedure ReplacementSourceOnTheAnalogsPageOnChange(Item)
	
	FillQuantityToReplace();
	FillInTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure SubstitutesSelectionModeStartChoice(Item, ChoiceData, StandardProcessing)
	
	TheModeOfSelectingAnalogsBeforeChangingThem = SubstitutesSelectionMode;
	
EndProcedure

&AtClient
Procedure SubstitutesSelectionModeOnChange(Item)
	
	If SubstitutesSelectionMode = TheModeOfSelectingAnalogsBeforeChangingThem Then
		Return;
	EndIf;
	
	FillInISServiceAttribute(Substitutes, SubstitutesSelectionMode);

	TheModeOfSelectingAnalogsBeforeChangingThem = SubstitutesSelectionMode;
	
	CurrentData = Items.UsedMaterials.CurrentData;
	
	If CurrentData <> Undefined Then
	
		SetSelectionByAvailableAnalogues(
			Items.Substitutes.RowFilter, CurrentData.ConnectionKey, SubstitutesSelectionMode);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure BalanceDisplayModeOnChange(Item)
	
	CurrentData = Items.UsedMaterials.CurrentData;
	FillInBalanceInWarehouse(ThisObject, SeparatePosition, Purpose);
	
	FillInISServiceAttribute(Substitutes, SubstitutesSelectionMode);

	TheModeOfSelectingAnalogsBeforeChangingThem = SubstitutesSelectionMode;
	
	If CurrentData <> Undefined Then
	
		SetSelectionByAvailableAnalogues(
			Items.Substitutes.RowFilter, CurrentData.ConnectionKey, SubstitutesSelectionMode);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionModeWarehouseOnChange(Item)
	
	Items.AnalogSelectionWarehouse.Visible = SelectionModeWarehouse = ManuallySpecifiedWarehouseMode();
	ProcessFormONChangingWarehouseSelection();
	
	CurrentData = Items.UsedMaterials.CurrentData;
	UpdateBalanceAfterWarehouseChange(SeparatePosition, Purpose);
	
	FillInISServiceAttribute(Substitutes, SubstitutesSelectionMode);

	TheModeOfSelectingAnalogsBeforeChangingThem = SubstitutesSelectionMode;
	
	If CurrentData <> Undefined Then
	
		SetSelectionByAvailableAnalogues(
			Items.Substitutes.RowFilter, CurrentData.ConnectionKey, SubstitutesSelectionMode);
			
		If SelectionModeWarehouse = WarehouseModeAccordingToDocument() Then
			MaterialRowWarehouse = CurrentData.Warehouse;
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure AnalogSelectionWarehouseOnChange(Item)
	
	ProcessFormONChangingWarehouseSelection();
	UpdateBalanceAfterWarehouseChange(SeparatePosition, Purpose);
	
	FillInISServiceAttribute(Substitutes, SubstitutesSelectionMode);

	TheModeOfSelectingAnalogsBeforeChangingThem = SubstitutesSelectionMode;
	
	CurrentData = Items.UsedMaterials.CurrentData;
	
	If CurrentData <> Undefined Then
	
		SetSelectionByAvailableAnalogues(
			Items.Substitutes.RowFilter, CurrentData.ConnectionKey, SubstitutesSelectionMode);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If PermissionValidityDate = PermissionsValidityDateBeforeChange Then
		Return;
	EndIf;	
	
	If SelectionPortions.Count() > 0 Then
		
		CallbackDescription = New CallbackDescription("DateOnChangeCompletion", ThisObject);
		QueryText = NStr("vi = 'Cần hủy bỏ đối tượng đã lọc để thực hiện giao dịch. Hủy đã lọc?';
						|ru = 'Необходимо отменить сохраненные подборы для выполнения операции. Отменить подборы?';
						|en = 'You must cancel saved pickings to perform the operation. Cancel pickings?'; fa = 'You must cancel saved pickings to perform the operation. Cancel pickings?';
						|it = 'È necessario annullare le selezioni salvate per l''esecuzione dell''operazione. Annullare le selezioni?';
						|pl = 'Należy anulować zapisane dobory dla wykonania operacji. Anulować dobory?';
						|tr = 'İşlemin gerçekleştirilmesi için kayıtlı seçimleri iptal etmeniz gerekmektedir. Seçimler iptal edilsin mi?'");
		
		ShowQueryBox(
			CallbackDescription, QueryText, QuestionDialogMode.YesNo, 45, DialogReturnCode.No,, DialogReturnCode.No);
		
	Else
		DateOfChangeOnServer(False);
	EndIf;	
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	If QuestionResult = DialogReturnCode.No Then
		PermissionValidityDate = PermissionsValidityDateBeforeChange;
		Return;	
	EndIf;
	
	DateOfChangeOnServer();
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer(CancelSelections = True)
	
	PermissionsValidityDateBeforeChange = PermissionValidityDate;
	
	If CancelSelections Then
		MaximumSelectionNumber = 0;
		SelectionPortions.Clear();
	EndIf;
	
	FillOutFormDataATServer(True);
	
EndProcedure

&AtClient
Procedure ProductsPresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.UsedMaterials.CurrentData;
	OpenForm("Catalog.Products.Form.ItemForm", New Structure("Key", CurrentData.Products), ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSubstitutes

&AtClient
Procedure SubstitutesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure SubstitutesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure SubstitutesOnStartEdit(Item, NewRow, Copy)
	
	AnalogsQuantityBeforeChange = Items.Substitutes.CurrentData.Count;
	
EndProcedure

&AtClient
Procedure SubstitutesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	ClearMessages();
	CurrentData = Items.Substitutes.CurrentData;
	
	If Not CancelEdit And CurrentData.Count <> AnalogsQuantityBeforeChange Then
		
		RecalculationIsNotPossible = False;
		CheckPossibilityOfRecalculation(RecalculationIsNotPossible);
		
		If RecalculationIsNotPossible Or Not ItIsPossibleToSelectAnalogue() Then
			CurrentData.Count = AnalogsQuantityBeforeChange;
		Else
			FillQuantityByPermission();
		EndIf;
		
	Else
		
		CurrentData.Count = AnalogsQuantityBeforeChange;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstitutesOnEditEnd(Item, NewRow, CancelEdit)
	
	Items.Substitutes.SelectedRows.Clear();
	Items.Substitutes.SelectedRows.Add(Items.Substitutes.CurrentRow);
	
EndProcedure

&AtClient
Procedure SubstitutesSelection(Item, RowSelected, Field, StandardProcessing)
	
	ClearMessages();
	
	If Field = Items.SubstitutesWarehouseStockBalance And Not GeneralParameters.DetailsMode Then
		
		If ItIsPossibleToSelectAnalogue() Then
		
			ConversionFactor_ = GetConversionFactor();
		
			If ConversionFactor_ > 0 Then
				
				CurrentData = Items.Substitutes.CurrentData;
				
				PackageData = CurrentData.PackageData;
				
				CurrentCount = CalculateAmountOfAnalogByCoefficient(
					CurrentData.NormativeStandard, ConversionFactor_, PackageData);
				
				CurrentData.Count = CurrentData.Count + CurrentCount;
				
				FillQuantityByPermission();
				
			EndIf;	
		
		EndIf;
		
	ElsIf Field = Items.SubstitutesProducts Then
		
		CurrentData = Items.Substitutes.CurrentData;
		OpenForm("Catalog.Products.Form.ItemForm", New Structure("Key", CurrentData.Products), ThisObject);
		
	ElsIf Field = Items.AnalogsResolutionPresentation Then
		
		CurrentData = Items.Substitutes.CurrentData;
		ShowValue(, CurrentData.Resolution);

	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsedMaterials

&AtClient
Procedure UsedMaterialsOnActivateRow(Item)
	
	If Items.Pages.CurrentPage = Items.PageMaterials Then
	
		If ThereAreInvalidPermissionsBeforeTheChange <> ThereAreInvalidPermissions(ThisObject) Then
			ThereAreInvalidPermissionsBeforeTheChange = Not ThereAreInvalidPermissionsBeforeTheChange;
			SetHyperlinkTitleSeeAlso("UsedMaterials");
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure UsedMaterialsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.UsedMaterialsThereAreSubstituteMaterials Then
		
		GoToSubstitutesSelection(Undefined);
		
	ElsIf Field = Items.UsedMaterialsProducts Then
		
		CurrentData = Items.UsedMaterials.CurrentData;
		OpenForm("Catalog.Products.Form.ItemForm", New Structure("Key", CurrentData.Products), ThisObject);
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PerformAReplacement_3(Command)
	
	RowsArray = UsedMaterials.FindRows(New Structure("Count", 0));
	If UsedMaterials.Count() > RowsArray.Count() Then
		NotifyChoice(New Structure("AddressInStorage", GetSelectionResult()));
	Else
		
		RowsArray = UsedMaterials.FindRows(New Structure("ThereAreSubstituteMaterials", True));
		If RowsArray.Count() = 0 Then
			Close();
		Else	
			
			QuestionFormParameters = New Structure;
			QuestionFormParameters.Insert("Title", NStr("vi = 'Lựa chọn các chất tương tự';
														|ru = 'Подбор аналогов';
														|en = 'Pick substitutes'; fa = 'انتخاب جایگزین‌ها';
														|it = 'Selezione degli analoghi';
														|pl = 'Dobór odpowiedników';
														|tr = 'İkamelerin seçimi'"));
			QuestionFormParameters.Insert("MessageText", NStr("vi = 'Chưa chọn mặt hàng tương tự nào. Đóng biểu mẫu chọn?';
																|ru = 'Ни один аналог не выбран. Закрыть форму подбора?';
																|en = 'No substitute has been picked. Close the picking form?'; fa = 'No substitute has been picked. Close the picking form?';
																|it = 'Non è stato selezionato nessun analogo. Chiudere il modulo di selezione?';
																|pl = 'Nie wybrano żadnego analogu. Zamknąć formularz wyboru?';
																|tr = 'Herhangi bir ikame seçilmedi. Seçim formu kapatılsın mı?'"));
			QuestionFormParameters.Insert("Buttons", "QuestionDialogMode.YesNo");
			QuestionFormParameters.Insert("DefaultButton", "DialogReturnCode.Yes");
			QuestionFormParameters.Insert("HighlightDefaultButton", True);
			QuestionFormParameters.Insert("PromptDontAskAgain", False);
			
			CallbackDescription = New CallbackDescription("PerformReplacementClosing", ThisObject);
			
			OpenForm("CommonForm.DoQueryBox", QuestionFormParameters, ThisObject, UUID,,, CallbackDescription); 
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformReplacementClosing(ClosingResult, AdditionalParameters) Export
	
	Response = Undefined;
	If ClosingResult = Undefined 
	 Or Not ClosingResult.Property("Value", Response) 
	 Or Response <> DialogReturnCode.Yes Then
	 	Return;
	EndIf;
	
	Close();
	
EndProcedure	

&AtClient
Procedure OpenReplacementHistory(Command)
	
	WarningText = "";
	
	ArrayOfSelectedRows = Items.UsedMaterials.SelectedRows;
	
	If ArrayOfSelectedRows.Count() = 0 Then
		
		WarningText = NStr("vi = 'Để hiển thị lịch sử thay thế, chọn (các) dòng.';
							|ru = 'Для отображения истории замен нужно выбрать строку(и).';
							|en = 'Select line (s) to display the replacement history.'; fa = 'Select line (s) to display the replacement history.';
							|it = 'Per visualizzare la cronologia delle sostituzioni è necessario selezionare una riga (righe).';
							|pl = 'Aby wyświetlić historię zastąpień należy wybrać wiersz(e).';
							|tr = 'Değişim geçmişinin görüntülenmesi için satır(lar) seçilmeli.'");
		
	Else	
		
		ArrayOfLineNumbers = New Array;
		
		SearchKeys = New Map;
		
		For Each RowID In ArrayOfSelectedRows Do
			
			CurrentRow = UsedMaterials.FindByID(RowID);
					
			SearchKey = StrTemplate("%1 %2 %3 %4", 
									CurrentRow.Products.UUID(), 
									CurrentRow.Characteristic.UUID(), 
									CurrentRow.Purpose.UUID(),
									CurrentRow.WithAssignment);
									
			SearchKeys.Insert(SearchKey);
			If SearchKeys.Count() > 1 Then
				
				WarningText = StrTemplate(
					NStr("vi = 'Chỉ có thể chọn đồng thời các dòng có mặt hàng%1 và mục đích giống nhau.';
						|ru = 'Одновременно можно выбрать строки только с одинаковой номенклатурой%1 и назначением.';
						|en = 'You can only select lines with the same item %1 and assignment at a time.'; fa = 'You can only select lines with the same item %1 and assignment at a time.';
						|it = 'Si possono selezionare contemporaneamente solo le righe con lo stesso articolo%1 e assegnazione.';
						|pl = 'Jednocześnie można wybrać wiersze tylko z jednakową pozycją%1 i przeznaczeniem.';
						|tr = 'Aynı anda sadece aynı ürün%1 ve atamaya sahip satırları seçebilirsiniz.'"),
					?(UseItemVariants, StrTemplate(NStr("vi = '%1 (theo đặc tính)';
														|ru = '%1(характеристикой)';
														|en = '%1(variant)'; fa = '%1(variant)';
														|it = '%1(con la caratteristica)';
														|pl = '%1(cechą)';
														|tr = '%1 (varyantlı)'"), " "), ""));
					
				Break;	
				
			EndIf;
			
			If CurrentRow.Count > 0 Then
				ArrayOfLineNumbers.Add(CurrentRow.OriginalLineNumber);
			EndIf;
			
		EndDo;
		
		If Not ValueIsFilled(WarningText) And ArrayOfLineNumbers.Count() = 0 Then
			WarningText = NStr("vi = 'Không có sự thay thế trong các dòng được tô sáng.';
								|ru = 'В выделенных строках замены отсутствуют.';
								|en = 'There are no replacements in the selected lines.'; fa = 'There are no replacements in the selected lines.';
								|it = 'Nelle righe evidenziate non ci sono sostituzioni.';
								|pl = 'Brak zastąpień w wybranych wierszach.';
								|tr = 'Belirtilen satırlarda herhangi bir değişim bulunmamaktadır.'");	
		EndIf;
	
	EndIf;
	
	If ValueIsFilled(WarningText) Then
		ShowMessageBox(, WarningText, 45);
		Return;
	EndIf;
	
	ListOfSelections = SelectionData_2(
		CurrentRow.Products, CurrentRow.Characteristic, ArrayOfLineNumbers);
	
	FormParameters = New Structure;
	FormParameters.Insert("ValueList", ListOfSelections);
	FormParameters.Insert("FormCaption", NStr("vi = 'Lịch sử thay thế';
												|ru = 'История замен';
												|en = 'Replacement history'; fa = 'سابقه جایگزینی';
												|it = 'Cronologia di sostituzioni';
												|pl = 'Historia zastąpień';
												|tr = 'Değişim geçmişi'"));
	FormParameters.Insert("TitleOKButton", NStr("vi = 'Hủy bỏ';
												|ru = 'Отменить';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annullare';
												|pl = 'Cancel';
												|tr = 'İptal et'"));
	FormParameters.Insert("TitleCancelButton", NStr("vi = 'Đóng';
													|ru = 'Закрыть';
													|en = 'Close'; fa = 'بستن';
													|it = 'Chiudere';
													|pl = 'Close';
													|tr = 'Kapat'"));
	
	OpenForm("CommonForm.FormOfMarkingOfItems", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure GoToSubstitutesSelection(Command)
	
	WarningText = "";
	
	ArrayOfSelectedRows = Items.UsedMaterials.SelectedRows;
	
	If ArrayOfSelectedRows.Count() = 0 Then
		
		WarningText = NStr("vi = 'Cần chọn (các) hàng';
							|ru = 'Необходимо выбрать строку(и)';
							|en = 'Highlight the line(s)'; fa = 'Highlight the line(s)';
							|it = 'È necessario selezionare la riga (le righe)';
							|pl = 'Należy wybrać wiersz(e)';
							|tr = 'Satır(lar) seçilmelidir'");
		
	Else
		
		SourceArrayOfSelectedStrings = CommonClientServer.CopyArray(ArrayOfSelectedRows);
		
		Items.UsedMaterials.CurrentRow = SourceArrayOfSelectedStrings[0];
		
		CurrentData = Items.UsedMaterials.CurrentData;
		ThereIsPositionWithAssignmentFlag = False;
		
		If Not CurrentData.ThereAreSubstituteMaterials Then
			
			WarningText = NStr("vi = 'Không tìm thấy sự tương tự cho hàng đã chọn';
								|ru = 'Для выделенной строки аналоги не найдены';
								|en = 'Substitutes are not found for the selected line'; fa = 'Substitutes are not found for the selected line';
								|it = 'Non sono trovati analoghi per la riga selezionata';
								|pl = 'Nie znaleziono analogicznego wiersza dla zaznaczonych';
								|tr = 'Belirtilen satıra ilişkin ikameler bulunmadı'");
			
		Else
			
			If SourceArrayOfSelectedStrings.Count() > ArrayOfSelectedRows.Count() Then
				For Each RowID In SourceArrayOfSelectedStrings Do
					If ArrayOfSelectedRows.Find(RowID) = Undefined Then  
						ArrayOfSelectedRows.Add(RowID);	
					EndIf;	
				EndDo;	
			EndIf;
			
			SearchKeys = New Map;
			
			For Each RowID In ArrayOfSelectedRows Do
				
				CurrentRow = UsedMaterials.FindByID(RowID);
				
				If CurrentRow.Count >= CurrentRow.ToReplace Then
					
					WarningText = StrTemplate(
						NStr("vi = 'Trong dòng số %1 đã thay thế tất cả số lượng có thể.';
							|ru = 'В строке №%1 все возможное количество заменено.';
							|en = 'In line No.%1 all the available quantity is replaced.'; fa = 'In line No.%1 all the available quantity is replaced.';
							|it = 'Nella riga №%1 è stata sostituita tutta la quantità possibile.';
							|pl = 'W wierszu №%1 wszystkie możliwe ilości zostały zastąpione.';
							|tr = '%1 numaralı satırda mümkün olan her miktar değiştirildi.'"), CurrentRow.LineNumber);
					
					Break;
					
				Else	
					
					SearchKey = StrTemplate("%1 %2 %3 %4", 
											CurrentRow.Products.UUID(), 
											CurrentRow.Characteristic.UUID(), 
											CurrentRow.Purpose.UUID(),
											CurrentRow.WithAssignment);
											
					SearchKeys.Insert(SearchKey);
					If SearchKeys.Count() > 1 Then
						
						WarningText = StrTemplate(
							NStr("vi = 'Cùng một lúc chỉ có thể chọn các dòng có sự phân tách và danh mục giống nhau%1.';
								|ru = 'Одновременно можно выбрать строки только с одинаковым обособлением и номенклатурой%1.';
								|en = 'You can only select lines with the same assignment and item at a time%1.'; fa = 'You can only select lines with the same assignment and item at a time%1.';
								|it = 'Одновременно можно выбрать строки только с одинаковым обособлением и номенклатурой%1.';
								|pl = 'You can only select lines with the same assignment and item at a time%1.';
								|tr = 'Одновременно можно выбрать строки только с одинаковым обособлением и номенклатурой%1.'"),
							?(UseItemVariants, StrTemplate(NStr("vi = '%1 (theo đặc tính)';
																|ru = '%1(характеристикой)';
																|en = '%1(variant)'; fa = '%1(variant)';
																|it = '%1(con la caratteristica)';
																|pl = '%1(cechą)';
																|tr = '%1 (varyantlı)'"), " "), ""));
							
						Break;	
						
					EndIf;
					
				EndIf;
				
				If CurrentRow.WithAssignment Then
				
					ThereIsPositionWithAssignmentFlag = True;
				
				EndIf;
				
			EndDo;
			
			If Not ValueIsFilled(SelectionModeWarehouse) Then
				SelectionModeWarehouse = ModeOfWarehousesAccordingToSecurityScheme();
			EndIf;
			
		EndIf;
		
		If ThereIsPositionWithAssignmentFlag Then
			BalanceDisplayMode = DisplayModeSeparateBalance();
		Else	
			BalanceDisplayMode = 0;
		EndIf;
		
		FilterAccordingToMaterial = New Structure("InterchangeableSubstitute, ThisIsASubstitute", True, True);
		ArrayOfAnalogs = Substitutes.FindRows(FilterAccordingToMaterial);
		For Each StringAnalog In ArrayOfAnalogs Do
			
			StringAnalog.AnalogueCoincidesWithMaterial 
				= (StringAnalog.Products = CurrentData.Products And StringAnalog.Characteristic = CurrentData.Characteristic);
		
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(WarningText) Then
		ShowMessageBox(, WarningText, 45);
		Return;
	EndIf;
	
	SetPermissionsPresentation(CurrentData.Products, CurrentData.Characteristic);
	
	FillInISServiceAttribute(Substitutes, SubstitutesSelectionMode);
	SetCurrentPage(ThisObject, "Substitutes", CurrentData.ConnectionKey, SubstitutesSelectionMode);
	
	If SelectionModeWarehouse = WarehouseModeAccordingToDocument()
	   And MaterialRowWarehouse <> CurrentData.Warehouse Then
	
		MaterialRowWarehouse = CurrentData.Warehouse;
		ProcessFormONChangingWarehouseSelection();
		UpdateBalanceAfterWarehouseChange(CurrentData.WithAssignment, CurrentData.Purpose);
		
	Else
		
		FillInBalanceInWarehouse(ThisObject, CurrentData.WithAssignment, CurrentData.Purpose);
	
	EndIf;
	
	SetAvailabilityOfBalanceDisplayMode(ThisObject);
	
EndProcedure

&AtClient
Procedure CancelCurrentSelection(Command)
	
	ProcessSelectionOfAnalogues(False);
	
	If UsedMaterials.Count() > 1 Then
		SetCurrentPage(ThisObject, "UsedMaterials");
	Else
		FillInTotals(ThisObject);
	EndIf;	
	
EndProcedure

&AtClient
Procedure Confirm_Selection(Command)
	
	ProcessSelectionOfAnalogues(True);
	
	If UsedMaterials.Count() > 1 Then
		SetCurrentPage(ThisObject, "UsedMaterials");
	EndIf;	
	
EndProcedure

&AtClient
Procedure HyperlinkSeeAlsoNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "InvalidPermissions" Then
	
		ListOfInvalidPermissions = New ValueList;
		
		SelectionBasedOnInvalidPermissions = New Structure("LineNumber");
		FillPropertyValues(SelectionBasedOnInvalidPermissions, Items.UsedMaterials.CurrentData);
	
		RowsArray = InvalidPermissions.FindRows(SelectionBasedOnInvalidPermissions);
		For Each TableRow In RowsArray Do
			
			If Not ValueIsFilled(TableRow.Resolution) Then
				Continue;
			EndIf;
			
			ListOfInvalidPermissions.Add(TableRow.Resolution);
			
		EndDo;
		
		FormParameters = New Structure("Filter", New Structure("Ref", ListOfInvalidPermissions));
		
		OpenForm("Document.EngineeringChangeOrder.ListForm", FormParameters, ThisObject);
		
	ElsIf FormattedStringURL = "BalancesAndAvailabilityOfAnalogues"
		  Or FormattedStringURL = "BalancesAndAvailabilityOfAnaloguesInAllWarehouses"
		  Or FormattedStringURL = "BalancesAndAvailabilityOfMaterialsAndAnaloguesInAllWarehouses" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("GenerateOnOpen", True);
		FormParameters.Insert("VariantKey",            "ByProductContext");
		FormParameters.Insert("FixedSettings",  New DataCompositionSettings);
		FormParameters.Insert("Filter",                   New Structure("ShowSeparateProducts", True));
		
		CurrentData = Items.Substitutes.CurrentData;
		If CurrentData <> Undefined Then
			
			ArrayOfSelectedRows = Items.Substitutes.SelectedRows;
			ItemList = New ValueList;
			ListOfCharacteristics = New ValueList;
			For Each SelectedRow In ArrayOfSelectedRows Do
				
				StringAnalogues = Substitutes.FindByID(SelectedRow);
				
				If ItemList.FindByValue(StringAnalogues.Products) = Undefined
				   And ValueIsFilled(StringAnalogues.Products) Then
				
					ItemList.Add(StringAnalogues.Products);
				
				EndIf;
				
				If ListOfCharacteristics.FindByValue(StringAnalogues.Characteristic) = Undefined Then
				
					ListOfCharacteristics.Add(StringAnalogues.Characteristic);
				
				EndIf;
				
			EndDo;
			
			If FormattedStringURL = "BalancesAndAvailabilityOfMaterialsAndAnaloguesInAllWarehouses" Then
			
				CurDataMaterials = Items.UsedMaterials.CurrentData;
				
				If CurDataMaterials <> Undefined Then
				
					If ItemList.FindByValue(CurDataMaterials.Products) = Undefined Then
				
						ItemList.Add(CurDataMaterials.Products);
					
					EndIf;
					
					If ListOfCharacteristics.FindByValue(CurDataMaterials.Characteristic) = Undefined Then
				
						ListOfCharacteristics.Add(CurDataMaterials.Characteristic);
					
					EndIf;
				
				EndIf;
			
			EndIf;
			
			FilterElement = FormParameters.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterElement.ComparisonType = DataCompositionComparisonType.InList;
			FilterElement.LeftValue = New DataCompositionField("Products");
			FilterElement.RightValue = ItemList;
			
			FilterElement = FormParameters.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterElement.ComparisonType = DataCompositionComparisonType.InList;
			FilterElement.LeftValue = New DataCompositionField("Characteristic");
			FilterElement.RightValue = ListOfCharacteristics;
			
			If BalanceDisplayMode = DisplayModeSeparateBalance()
			   And Not ValueIsFilled(Purpose) Then
				
				FilterElement = FormParameters.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
				FilterElement.LeftValue  = New DataCompositionField("Purpose");
				FilterElement.RightValue = Undefined;
				
				FormParameters.Filter.ShowSeparateProducts = False;
				
			ElsIf BalanceDisplayMode = DisplayModeSeparateBalance()
					And ValueIsFilled(Purpose) Then
			
				FilterElement = FormParameters.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
				FilterElement.LeftValue  = New DataCompositionField("Purpose");
				FilterElement.RightValue = Purpose;
				
				FormParameters.Filter.ShowSeparateProducts = True;
			
			EndIf;
			
			If FormattedStringURL = "BalancesAndAvailabilityOfAnalogues"
			   And ValueIsFilled(CurrentData.Warehouse) Then
			
				FilterElement = FormParameters.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
				FilterElement.LeftValue = New DataCompositionField("Warehouse");
				FilterElement.RightValue = CurrentData.Warehouse;
				FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
				
			EndIf;
				
		EndIf;
		
		OpenForm("Report.StockAvailability.Form", FormParameters, ThisObject);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

#Region UsedMaterials

&AtServer
Procedure FillQuantityToReplace()
	
	If ReplacementSource = 0 Then
		
		For Each TableRow In UsedMaterials Do
			TableRow.ToReplace = TableRow.CountByDocument;	
		EndDo;
		
	Else
		
		FilterFields = "Products, Characteristic, Purpose, WithAssignment";
		FilterByRows = New Structure(FilterFields);
		
		TableOfMaterials = UsedMaterials.Unload();
		TableOfMaterials.Indexes.Add(FilterFields);
		
		While TableOfMaterials.Count() > 0 Do
			
			TableRow = TableOfMaterials[0];
			
			TotalQuantityToReplace = TableRow.NotProvide 
									 + TableRow.ToSupply_
									 + ?(ReplacementSource = 1, TableRow.SuppliedByDate, 0);
				
			FillPropertyValues(FilterByRows, TableRow);	
				
			FoundRows = TableOfMaterials.FindRows(FilterByRows);
			For Each FoundRow In FoundRows Do
				
				If TotalQuantityToReplace > 0 Then
					
					QuantityToReplaceByLine = Min(FoundRow.CountByDocument, TotalQuantityToReplace);
					UsedMaterials[FoundRow.LineNumber - 1].ToReplace = QuantityToReplaceByLine;
					
					TotalQuantityToReplace = TotalQuantityToReplace - QuantityToReplaceByLine;
					
				Else
					UsedMaterials[FoundRow.LineNumber - 1].ToReplace = 0;	
				EndIf;
				
				TableOfMaterials.Delete(FoundRow);
				
			EndDo;	
				
		EndDo;
		
	EndIf;	
	
EndProcedure

&AtServer
Function ConnectionKey(Id, Full = True)
	
	Return Documents.EngineeringChangeOrder.ConnectionKey(Id, Full);
	
EndFunction

#EndRegion

#Region Substitutes

&AtServer
Procedure FillQuantityByPermission()
	
	CurLineAnalogues = Substitutes.FindByID(Items.Substitutes.CurrentRow);
	CurLineMaterials = UsedMaterials.FindByID(Items.UsedMaterials.CurrentRow);
	
	InterchangeableSubstitute = CurLineAnalogues.InterchangeableSubstitute;
	CurRowLinkKey = CurLineMaterials.ConnectionKey;
	
	ArrayOfSuggestions = New Array;
	
	FilterStructure1 = New Structure("Resolution, ThisIsASubstitute", CurLineAnalogues.Resolution);
	
	If InterchangeableSubstitute Then
		
		CalculationCoefficient = 0;
		FilterStructure1.ThisIsASubstitute = True;
		RowsArray = Substitutes.FindRows(FilterStructure1);
		
		For Each StringAnalogues In RowsArray Do
			CalculationCoefficient = CalculationCoefficient + StringAnalogues.Count / StringAnalogues.NormativeStandard;
		EndDo;
		
	Else
		
		CalculationCoefficient = ProductionClientServer.CoefficientByStandard(
			False, CurLineAnalogues.Count, CurLineAnalogues.NormativeStandard, CurLineAnalogues.PackageData);	
		
	EndIf;
	
	FilterStructure1.ThisIsASubstitute = False;
	RowsArray = Substitutes.FindRows(FilterStructure1);
	For Each StringAnalogues In RowsArray Do
		
		KeyPosition = StrFind(StringAnalogues.ConnectionKey, CurRowLinkKey);
		If InterchangeableSubstitute
		   And KeyPosition = 0 Then
			Continue;	
		EndIf;
		
		AllocationBase = Round(StringAnalogues.NormativeStandard * CalculationCoefficient
			* StringAnalogues.PackageData.Numerator / StringAnalogues.PackageData.Denominator - StringAnalogues.Count, 3);
		
		If AllocationBase = 0 Then
			Continue;
		EndIf;
		
		StringAnalogues.Count = StringAnalogues.NormativeStandard * CalculationCoefficient
				* StringAnalogues.PackageData.Numerator / StringAnalogues.PackageData.Denominator;
		
		If StringAnalogues.Count > 0 Then
			ArrayOfSuggestions.Add(TooltipText(StringAnalogues));
		EndIf;	
		
		If KeyPosition > 0 Then
			
			ArrayOfSelectedRows = Items.UsedMaterials.SelectedRows;
			For Each SelectedRow In ArrayOfSelectedRows Do
				
				NewMaterials = UsedMaterials.FindByID(SelectedRow);
				SetNumberInLine(NewMaterials, AllocationBase);
				
				If AllocationBase = 0 Then
					Break;
				EndIf;	
				
			EndDo;	
			
		EndIf;	
		
		If AllocationBase <> 0 Then
		
			ArrayOfCommunicationKeys = StrSplit(StringAnalogues.ConnectionKey, ";", False);
			For Each IDCommunicationKey In ArrayOfCommunicationKeys Do
				
				ConnectionKey = ConnectionKey(IDCommunicationKey);
				If ConnectionKey = CurRowLinkKey Then
					Continue;
				EndIf;	
				
				ContentLines = UsedMaterials.FindRows(New Structure("ConnectionKey", ConnectionKey));
				
				If ContentLines.Count() > 0 Then
				
					NewMaterials = ContentLines[0];
					SetNumberInLine(NewMaterials, AllocationBase);
					
					If AllocationBase = 0 Then
						Break;
					EndIf;
				
				EndIf;
				
			EndDo;
			
		ElsIf AllocationBase = 0 And InterchangeableSubstitute Then
			Break;
		EndIf;
		
	EndDo;
	
	FillInTotals(ThisObject);
	
	TooltipIsReplaced = ?(ArrayOfSuggestions.Count() > 0, "Replaced: " + StrConcat(ArrayOfSuggestions, "; "), "");
	
	If InterchangeableSubstitute Then
	
		FilterStructure1.Insert("Products", CurLineAnalogues.Products);
		FilterStructure1.Insert("Characteristic", CurLineAnalogues.Characteristic);
		FilterStructure1.Insert("Warehouse", CurLineAnalogues.Warehouse);
	
	EndIf;
	
	FilterStructure1.ThisIsASubstitute = True;
	RowsArray = Substitutes.FindRows(FilterStructure1);
	For Each StringAnalogues In RowsArray Do
		
		StringAnalogues.TooltipIsReplaced = TooltipIsReplaced;
		
		If StringAnalogues.LineNumber <> CurLineAnalogues.LineNumber Then
			StringAnalogues.Count = StringAnalogues.NormativeStandard * CalculationCoefficient
				* StringAnalogues.PackageData.Numerator / StringAnalogues.PackageData.Denominator;
		EndIf;
		
		BalanceInStockBeforeChange = StringAnalogues.WarehouseStockBalance;
		
		StringAnalogues.WarehouseStockBalance = 
			StringAnalogues.StockBalanceConfirmed 
			- GetTotalNumberOfAnalogues(StringAnalogues.Products, StringAnalogues.Characteristic, StringAnalogues.ThisIsASubstitute);
		
		If StringAnalogues.WarehouseStockBalance <> BalanceInStockBeforeChange Then
			SetNumberOfAvailableBalances(StringAnalogues);
		EndIf;
			
	EndDo;
	
	InstallInscriptionLackOfAnalogues(ThisObject);
	SetAvailabilityOfBalanceDisplayMode(ThisObject);
		
EndProcedure

&AtServer
Procedure SetNumberOfAvailableBalances(DataString1)
	
	FilterStructure1 = New Structure("Products, Characteristic, ThisIsASubstitute");
	FillPropertyValues(FilterStructure1, DataString1);
	
	RowsArray = Substitutes.FindRows(FilterStructure1);
	For Each StringAnalogues In RowsArray Do
	
		FillPropertyValues(StringAnalogues, DataString1, "WarehouseStockBalance");
			
		SetThereAreLeftoversFlag(StringAnalogues);
			
	EndDo;	
	
EndProcedure

&AtServer
Procedure SetThereAreLeftoversFlag(DataString1)
	
	IsBalance = DataString1.WarehouseStockBalance >= DataString1.NormativeStandard
		* DataString1.PackageData.Numerator / DataString1.PackageData.Denominator;
	If DataString1.IsBalance = IsBalance Then
		Return;
	EndIf;
	
	InstallThereAreLeftovers = True;
	
	FilterStructure1 = New Structure("Resolution, IsBalance, ThisIsASubstitute");
	FillPropertyValues(FilterStructure1, DataString1);
	
	RowsArray = Substitutes.FindRows(FilterStructure1);
	If IsBalance
	   And Not DataString1.InterchangeableSubstitute Then
		For Each StringAnalogues In RowsArray Do
			If StringAnalogues.WarehouseStockBalance < DataString1.NormativeStandard
				* DataString1.PackageData.Numerator / DataString1.PackageData.Denominator Then
				InstallThereAreLeftovers = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	FilterStructure1.Delete("ThisIsASubstitute");
	RowsArray = Substitutes.FindRows(FilterStructure1);
	If InstallThereAreLeftovers Then
		For Each StringAnalogues In RowsArray Do
			
			ThereAreBalancesOnLine = StringAnalogues.WarehouseStockBalance >= StringAnalogues.NormativeStandard
				* StringAnalogues.PackageData.Numerator / StringAnalogues.PackageData.Denominator;
			StringAnalogues.IsBalance = ThereAreBalancesOnLine;
			
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetNumberInLine(TableRow, ValueQuantity)
	
	If ValueQuantity > 0
	   And TableRow.Count < TableRow.ToReplace
	 Or ValueQuantity < 0	
	   And TableRow.Count - TableRow.QuantityConfirmed > 0 Then
		
		Character = ?(ValueQuantity < 0, -1, 1);
		
		CountBalance = ?(ValueQuantity > 0,
							  TableRow.ToReplace - TableRow.Count,
							  TableRow.Count - TableRow.QuantityConfirmed);
				
		DistributionQuantity = Min(CountBalance, ValueQuantity * Character);
		
		TableRow.Count = TableRow.Count + DistributionQuantity * Character;
			
		ValueQuantity = ValueQuantity - DistributionQuantity * Character;
		
	EndIf;	
		
EndProcedure	

&AtServer
Function GetSelectionResult()
	
	If Substitutes.Count() > Substitutes.FindRows(New Structure("Count", 0)).Count() Then
		ProcessSelectionOfAnalogues(True);
	EndIf;	
	
	SelectionTable = SelectionPortions.Unload(
		, "SelectionNumber, OriginalLineNumber, ConnectionKey, WithAssignment, Purpose,"
		  + "Products, Characteristic, Count, "
		  + "WarehouseStockBalance, Warehouse, Resolution, ThisIsASubstitute");
	
	Return PutToTempStorage(SelectionTable, UUID);
	
EndFunction	

&AtClient
Procedure CheckPossibilityOfRecalculation(Cancel)
	
	ClearMessages();
	MessageText = "";
	
	CurDataAnalogues = Items.Substitutes.CurrentData;
	
	StandardCoefficient = ProductionClientServer.CoefficientByStandard(
		False, CurDataAnalogues.Count, CurDataAnalogues.NormativeStandard, CurDataAnalogues.PackageData);
	
	If CurDataAnalogues.ControlMultiplier And StandardCoefficient <> Int(StandardCoefficient) Then
		
		MessageText = NStr("vi = 'Nhập bội số của tiêu chuẩn.';
							|ru = 'Введите количество кратное нормативу.';
							|en = 'Enter the amount multiple of the standard'; fa = 'Enter the amount multiple of the standard';
							|it = 'Inserite un numero multiplo della quantità standard.';
							|pl = 'Wprowadź ilość wielokrotną normie.';
							|tr = 'Miktarı standardın katları olarak girin.'");
		
	Else
	
		CurDataMaterials = Items.UsedMaterials.CurrentData;
		
		FilterStructure1 = New Structure("Resolution, Products, Characteristic, ThisIsASubstitute");
		FillPropertyValues(FilterStructure1, CurDataAnalogues, "Resolution");
		FillPropertyValues(FilterStructure1, CurDataMaterials, "Products, Characteristic");
		
		FilterStructure1.ThisIsASubstitute = False;
		
		StringAnalogues = Substitutes.FindRows(FilterStructure1)[0];
		
		SubstitutesCount = CurDataAnalogues.Count;
		SubstitutesNormativeStandard = CurDataAnalogues.NormativeStandard;
		AnaloguesPackagingData = CurDataAnalogues.PackageData;
		
		MaterialsStandard = StringAnalogues.NormativeStandard;
		MaterialsPackingData = StringAnalogues.PackageData;
			
		QuantityDifferenceAnalog = (SubstitutesCount - AnalogsQuantityBeforeChange)
			* ?(AnalogsQuantityBeforeChange > SubstitutesCount, -1, 1);
			
		CalculationCoefficient = ProductionClientServer.CoefficientByStandard(
					False, QuantityDifferenceAnalog, SubstitutesNormativeStandard, AnaloguesPackagingData);
		
		QuantityDifference = Round(MaterialsStandard * CalculationCoefficient
					* MaterialsPackingData.Numerator / MaterialsPackingData.Denominator, 3);
		NumberOfPages = ?(AnalogsQuantityBeforeChange > SubstitutesCount, TotalReplaced, TotalLeftToReplace);
		
		If QuantityDifference > NumberOfPages Then
			
			MessageText = StrTemplate(
				NStr("vi = 'Để thực hiện thay thế, không đủ %1 %2 nguyên liệu đã chọn %3';
					|ru = 'Для выполнения замены не хватает %1 %2 выбранного материала %3';
					|en = '%1 %2 of the selected material %3 is missing to complete the replacement'; fa = '%1 %2 of the selected material %3 is missing to complete the replacement';
					|it = 'Per la sostituzione manca %1%2 del materiale selezionato %3';
					|pl = 'Dla wykonania zmiany nie wystarcza %1 %2 wybranego materiału %3';
					|tr = 'Değişimin gerçekleştirilmesi için %3 seçili malzemenin %2 %1 yetersiz'"),
				Round(QuantityDifference - NumberOfPages, 3),
				StringAnalogues.UnitOfMeasurePresentation,
				ProductsClientServer.ProductPresentation(StringAnalogues.Products, StringAnalogues.Characteristic));
			
		ElsIf AnalogsQuantityBeforeChange < SubstitutesCount Then
			
			If Not CurDataAnalogues.InterchangeableSubstitute Then
				FilterStructure1.Delete("Products");
				FilterStructure1.Delete("Characteristic");
			EndIf;
			
			RowsArray = Substitutes.FindRows(FilterStructure1);
			If RowsArray.Count() > 1 Then
				
				For Each StringAnalogues In RowsArray Do
					
					If StringAnalogues.Products = CurDataMaterials.Products
					   And StringAnalogues.Characteristic = CurDataMaterials.Characteristic Then
					   	Continue;
					EndIf;
					
					TotalRequiredMaterial = GetTotalAmountOfMaterialRequired(
						StringAnalogues.Products, StringAnalogues.Characteristic);
					
					TotalReplacedMaterial = GetTotalNumberOfAnalogues(
						StringAnalogues.Products, StringAnalogues.Characteristic, StringAnalogues.ThisIsASubstitute);
					
					MaterialsStandard = StringAnalogues.NormativeStandard;
					MaterialsPackingData = StringAnalogues.PackageData;
					
					QuantityDifference = Round(MaterialsStandard * CalculationCoefficient
								* MaterialsPackingData.Numerator / MaterialsPackingData.Denominator, 3);
					NumberOfPages = TotalRequiredMaterial - TotalReplacedMaterial;
					
					If QuantityDifference > NumberOfPages Then
						
						MessageText = MessageText + ?(ValueIsFilled(MessageText), Chars.LF, "") 
							+ StrTemplate(
								NStr("vi = '%1 %2 nguyên vật liệu %3';
									|ru = '%1 %2 материала %3';
									|en = '%1 %2 material %3'; fa = '%1 %2 material %3';
									|it = '%1 %2 del materiale %3';
									|pl = '%1 %2 materiału %3';
									|tr = '%3 malzemesinin %2 %1'"),
								QuantityDifference - NumberOfPages,
								StringAnalogues.UnitOfMeasurePresentation,	
								ProductsClientServer.ProductPresentation(StringAnalogues.Products, StringAnalogues.Characteristic));
						
					EndIf;

				EndDo;	
				
				If ValueIsFilled(MessageText) Then
					
					MessageText = NStr("vi = 'Không đủ để hoàn thành việc thay thế';
										|ru = 'Для выполнения замены не хватает';
										|en = 'Not enough to complete the replacement'; fa = 'Not enough to complete the replacement';
										|it = 'Per la sostituzione manca';
										|pl = 'Dla wykonania zastąpienia brakuje';
										|tr = 'Değişimin gerçekleştirilmesi için yetersiz'") 
								   + ?(StrFind(MessageText, Chars.LF) > 0, Chars.LF, " ")
								   + MessageText;
					
				EndIf;
				
			EndIf;
			
		EndIf;
	
	EndIf;
		
	If ValueIsFilled(MessageText) Then
		CommonClient.MessageToUser(MessageText,,,, Cancel);
	EndIf;

EndProcedure

&AtClient
Function GetConversionFactor()
	
	ConversionFactor_ = 0;
	
	If TotalLeftToReplace = 0 Then
		Return ConversionFactor_;
	EndIf;
	
	CurDataAnalogues = Items.Substitutes.CurrentData;
	
	If CurDataAnalogues.WarehouseStockBalance = 0 Or Not CurDataAnalogues.IsBalance Then
		Return ConversionFactor_;
	EndIf;
	
	CurDataMaterials = Items.UsedMaterials.CurrentData;
	
	FilterStructure1 = New Structure("Resolution, Products, Characteristic, ThisIsASubstitute");
	FillPropertyValues(FilterStructure1, CurDataAnalogues, "Resolution");
	FillPropertyValues(FilterStructure1, CurDataMaterials, "Products, Characteristic");
	
	FilterStructure1.ThisIsASubstitute = False;
	
	StringAnalogues = Substitutes.FindRows(FilterStructure1)[0];
	
	MaterialsStandard = StringAnalogues.NormativeStandard;
	MaterialPackingData = StringAnalogues.PackageData;
	
	ConversionFactor_ = ProductionClientServer.CoefficientByStandard(
		StringAnalogues.ControlMultiplier, TotalLeftToReplace, MaterialsStandard, MaterialPackingData);
		
	If CurDataAnalogues.InterchangeableSubstitute Then
		
		CoefficientOfPresenceOfAnalogue = ProductionClientServer.CoefficientByStandard(
			StringAnalogues.ControlMultiplier, 
			CurDataAnalogues.WarehouseStockBalance, 
			CurDataAnalogues.NormativeStandard, 
			CurDataAnalogues.PackageData);
			
		Return Min(CoefficientOfPresenceOfAnalogue, ConversionFactor_);
		
	EndIf;
	
	If ConversionFactor_ > 0 Then
		
		FilterStructure1.Delete("Products");
		FilterStructure1.Delete("Characteristic");
		
		RowsArray = Substitutes.FindRows(FilterStructure1);
		If RowsArray.Count() > 1 Then
			
			For Each StringAnalogues In RowsArray Do
				
				If StringAnalogues.Products = CurDataMaterials.Products
				   And StringAnalogues.Characteristic = CurDataMaterials.Characteristic Then
				   	Continue;
				EndIf;
				
				TotalRequiredMaterial = GetTotalAmountOfMaterialRequired(
					StringAnalogues.Products, StringAnalogues.Characteristic);
				
				TotalReplacedMaterial = GetTotalNumberOfAnalogues(
					StringAnalogues.Products, StringAnalogues.Characteristic, StringAnalogues.ThisIsASubstitute);
				
				MaterialsStandard = StringAnalogues.NormativeStandard;
				MaterialPackingData = StringAnalogues.PackageData;
				
				ConversionFactor_ = Min(
					ConversionFactor_, 
					ProductionClientServer.CoefficientByStandard(
						StringAnalogues.ControlMultiplier, TotalRequiredMaterial - TotalReplacedMaterial,
						MaterialsStandard, MaterialPackingData));
				
				If ConversionFactor_ = 0 Then
					Break;
				EndIf;
				
			EndDo;
		
		EndIf;
	
	EndIf;
	
	If ConversionFactor_ > 0 Then
	
		FilterStructure1.ThisIsASubstitute = True;
		
		RowsArray = Substitutes.FindRows(FilterStructure1);
		For Each StringAnalogues In RowsArray Do
			
			SubstitutesNormativeStandard = StringAnalogues.NormativeStandard;
			AnaloguesPackagingData = StringAnalogues.PackageData;
			
			ConversionFactor_ = Min(
				ConversionFactor_,
				ProductionClientServer.CoefficientByStandard(
					StringAnalogues.ControlMultiplier, StringAnalogues.WarehouseStockBalance, SubstitutesNormativeStandard, AnaloguesPackagingData));
			
			If ConversionFactor_ = 0 Then
				Break;
			EndIf;
			
		EndDo;
	
	EndIf;
	
	Return ConversionFactor_;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure FillInServiceDetailsOfTableParts(ReFilling_ = False)
	
	If Not ReFilling_ Then
	
		StructureOfActions = New Structure("FillInFeatureAttribute");
		StructureOfActions.FillInFeatureAttribute = 
			New Structure("Products", "ItemVariantsAreUsed");
			
		ProductsServer.FillInServiceDetailsForProductInCollection(UsedMaterials, StructureOfActions);
	
	EndIf;
	
	StructureOfActions = New Structure("FillInFeatureAttribute");
	StructureOfActions.FillInFeatureAttribute = 
		New Structure("Products", "ItemVariantsAreUsed");
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Substitutes, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInISServiceAttribute(Table, Mode)
	
	If Mode <> 1 Then
		Return;
	EndIf;
	
	For Each TableRow In Table Do
		TableRow.IsBalanceInternal = TableRow.IsBalance Or TableRow.StockBalanceConfirmed > 0; 	
	EndDo;
	
EndProcedure	

&AtServerNoContext
Function TooltipText(StringAnalogues)
	
	If ValueIsFilled(StringAnalogues.Characteristic) Then
		
		TooltipText = 
			StrTemplate("%1 %2%3%4 %5 %6%7", 
				StringAnalogues.ProductsPresentation, 
				"(", 
				StringAnalogues.CharacteristicPresentation, 
				")", 
				NStr("vi = 'trong số';
					|ru = 'в кол-ве';
					|en = 'in the amount'; fa = 'in the amount';
					|it = 'in quantità';
					|pl = 'w ilości';
					|tr = 'miktarda'"), 
				Format(StringAnalogues.Count, "NG="),
				StringAnalogues.UnitOfMeasurePresentation);
			
	Else
		
		TooltipText = 
			StrTemplate("%1 %2 %3%4", 
				StringAnalogues.ProductsPresentation, 
				NStr("vi = 'trong số';
					|ru = 'в кол-ве';
					|en = 'in the amount'; fa = 'in the amount';
					|it = 'in quantità';
					|pl = 'w ilości';
					|tr = 'miktarda'"), 
				Format(StringAnalogues.Count, "NG="),
				StringAnalogues.UnitOfMeasurePresentation);
		
	EndIf;	
	
	Return TooltipText;
	
EndFunction	

&AtServer
Procedure CancelSelections(PickUpNumbers)
	
	CurSelectionIndex = PickUpNumbers.Find(-1); 
	If CurSelectionIndex <> Undefined Then
		
		ProcessSelectionOfAnalogues(False);
		
		PickUpNumbers.Delete(CurSelectionIndex);
		
	EndIf;
	
	If PickUpNumbers.Count() > 0 Then
		
		CancelPortionsOfSelections(PickUpNumbers);
		
	EndIf;
	
	FillInTotals(ThisObject);
	
	UpdateHintsReplacementCapability();
	
EndProcedure	

&AtServer
Procedure CancelPortionsOfSelections(PickUpNumbers)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SelectionPortions.SelectionNumber AS SelectionNumber,
	|	SelectionPortions.OriginalLineNumber AS OriginalLineNumber,
	|	SelectionPortions.Products AS Products,
	|	SelectionPortions.Characteristic AS Characteristic,
	|	SelectionPortions.Count AS Count,
	|	SelectionPortions.WarehouseStockBalance AS WarehouseStockBalance,
	|	SelectionPortions.ThisIsASubstitute AS ThisIsASubstitute
	|INTO SelectionPortions
	|FROM
	|	&SelectionPortions AS SelectionPortions
	|
	|INDEX BY
	|	SelectionNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectionPortions.SelectionNumber AS SelectionNumber,
	|	SelectionPortions.OriginalLineNumber AS OriginalLineNumber,
	|	SelectionPortions.Products AS Products,
	|	SelectionPortions.Characteristic AS Characteristic,
	|	SelectionPortions.Count AS Count,
	|	SelectionPortions.WarehouseStockBalance AS WarehouseStockBalance,
	|	SelectionPortions.ThisIsASubstitute AS ThisIsASubstitute
	|INTO CanceledSelections
	|FROM
	|	SelectionPortions AS SelectionPortions
	|WHERE
	|	SelectionPortions.SelectionNumber IN(&NumbersArray)
	|
	|INDEX BY
	|	ThisIsASubstitute,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfBalancesBySelection.Products AS Products,
	|	TableOfBalancesBySelection.Characteristic AS Characteristic,
	|	SUM(TableOfBalancesBySelection.WarehouseStockBalance) AS WarehouseStockBalance
	|INTO RemainingRebounds
	|FROM
	|	(SELECT
	|		CanceledSelections.SelectionNumber AS SelectionNumber,
	|		CanceledSelections.Products AS Products,
	|		CanceledSelections.Characteristic AS Characteristic,
	|		MAX(CanceledSelections.WarehouseStockBalance) AS WarehouseStockBalance
	|	FROM
	|		CanceledSelections AS CanceledSelections
	|	WHERE
	|		CanceledSelections.ThisIsASubstitute
	|		AND CanceledSelections.WarehouseStockBalance > 0
	|	
	|	GROUP BY
	|		CanceledSelections.SelectionNumber,
	|		CanceledSelections.Products,
	|		CanceledSelections.Characteristic) AS TableOfBalancesBySelection
	|
	|GROUP BY
	|	TableOfBalancesBySelection.Products,
	|	TableOfBalancesBySelection.Characteristic
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectionPortions.SelectionNumber AS SelectionNumber,
	|	SelectionPortions.Products AS Products,
	|	SelectionPortions.Characteristic AS Characteristic,
	|	SUM(SelectionPortions.Count) AS Count,
	|	MAX(SelectionPortions.WarehouseStockBalance) AS WarehouseStockBalance,
	|	MAX(RemainingRebounds.WarehouseStockBalance) AS BalanceInStockCancellable
	|INTO AdjustedSelections
	|FROM
	|	SelectionPortions AS SelectionPortions
	|		LEFT JOIN RemainingRebounds AS RemainingRebounds
	|		ON SelectionPortions.Products = RemainingRebounds.Products
	|			AND SelectionPortions.Characteristic = RemainingRebounds.Characteristic
	|WHERE
	|	SelectionPortions.ThisIsASubstitute
	|	AND NOT SelectionPortions.SelectionNumber IN (&NumbersArray)
	|	AND RemainingRebounds.WarehouseStockBalance IS NOT NULL 
	|
	|GROUP BY
	|	SelectionPortions.SelectionNumber,
	|	SelectionPortions.Products,
	|	SelectionPortions.Characteristic
	|
	|HAVING
	|	SUM(SelectionPortions.Count) > MAX(SelectionPortions.WarehouseStockBalance)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdjustedSelections.Products AS Products,
	|	AdjustedSelections.Characteristic AS Characteristic,
	|	CASE
	|		WHEN SUM(AdjustedSelections.Count) - SUM(AdjustedSelections.WarehouseStockBalance) > MAX(AdjustedSelections.BalanceInStockCancellable)
	|			THEN MAX(AdjustedSelections.BalanceInStockCancellable)
	|		ELSE SUM(AdjustedSelections.Count) - SUM(AdjustedSelections.WarehouseStockBalance)
	|	END AS Balance
	|INTO AdjustedBalances
	|FROM
	|	AdjustedSelections AS AdjustedSelections
	|
	|GROUP BY
	|	AdjustedSelections.Products,
	|	AdjustedSelections.Characteristic
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdjustedSelections.SelectionNumber AS SelectionNumber,
	|	AdjustedSelections.Products AS Products,
	|	AdjustedSelections.Characteristic AS Characteristic,
	|	AdjustedSelections.Count - AdjustedSelections.WarehouseStockBalance AS QuantityToFill,
	|	AdjustedBalances.Balance AS RemainderToDistribution
	|FROM
	|	AdjustedSelections AS AdjustedSelections
	|		LEFT JOIN AdjustedBalances AS AdjustedBalances
	|		ON AdjustedSelections.Products = AdjustedBalances.Products
	|			AND AdjustedSelections.Characteristic = AdjustedBalances.Characteristic
	|
	|ORDER BY
	|	SelectionNumber
	|TOTALS
	|	MAX(RemainderToDistribution)
	|BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CanceledSelections.OriginalLineNumber AS OriginalLineNumber,
	|	SUM(CanceledSelections.Count) AS Count
	|FROM
	|	CanceledSelections AS CanceledSelections
	|WHERE
	|	NOT CanceledSelections.ThisIsASubstitute
	|
	|GROUP BY
	|	CanceledSelections.OriginalLineNumber";
	
	Query.SetParameter(
		"SelectionPortions", 
		SelectionPortions.Unload(
			, "SelectionNumber, OriginalLineNumber, Products, Characteristic, Count, WarehouseStockBalance, ThisIsASubstitute"));
			
	Query.SetParameter("NumbersArray", PickUpNumbers);	
		
	ResultsArray = Query.ExecuteBatch();
	
	SampleMaterials = ResultsArray[ResultsArray.UBound()].Select();
	While SampleMaterials.Next() Do
		NewMaterials = UsedMaterials.FindRows(New Structure("OriginalLineNumber", SampleMaterials.OriginalLineNumber))[0];
		NewMaterials.Count = NewMaterials.Count - SampleMaterials.Count;
		NewMaterials.QuantityConfirmed = NewMaterials.QuantityConfirmed - SampleMaterials.Count;
	EndDo;
	
	BalanceSelectionParameters = New Structure("Products, Characteristic, Warehouse, WithAssignment, Purpose");
	StructureOfSearchForAnalogues = New Structure("SelectionNumber, ThisIsASubstitute, SelectionOverBalance",, True, False);
	FilterByANumber = New Structure("SelectionNumber");
	For Each SelectionNumber In PickUpNumbers Do
		
		StructureOfSearchForAnalogues.SelectionNumber = SelectionNumber;
		RowsArray = SelectionPortions.FindRows(StructureOfSearchForAnalogues);
		For Each TableRow In RowsArray Do
			
			FillPropertyValues(BalanceSelectionParameters, TableRow);
			ArrayOfBalancesOfAnalogues = RemnantsOfAnalogues.FindRows(BalanceSelectionParameters);
			
			For Each ArrayRow In ArrayOfBalancesOfAnalogues Do
				ArrayRow.AvailableForInventoryAllocation = ArrayRow.AvailableForInventoryAllocation + TableRow.Count;
			EndDo;
			
		EndDo;
		
		FilterByANumber.SelectionNumber = SelectionNumber;
		RowsArray = SelectionPortions.FindRows(FilterByANumber);
		For Each TableRow In RowsArray Do
			SelectionPortions.Delete(TableRow);
		EndDo;
		
	EndDo;
	
	FillInBalanceInWarehouse(ThisObject, SeparatePosition, Purpose);
	
	FilterStructure1 = New Structure("Products, Characteristic, SelectionNumber");
	
	SelectionOfProducts = ResultsArray[ResultsArray.UBound() - 1].Select(QueryResultIteration.ByGroups);
	While SelectionOfProducts.Next() Do
		
		SampleCharacteristics = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
		While SampleCharacteristics.Next() Do
			
			RemainderToDistribution = SampleCharacteristics.RemainderToDistribution;
			FillPropertyValues(FilterStructure1, SampleCharacteristics,, "SelectionNumber");
			
			SelectionSelectionNumber = SampleCharacteristics.Select();
			While SelectionSelectionNumber.Next() Do
				
				BalanceInHand = Min(RemainderToDistribution, SelectionSelectionNumber.QuantityToFill);
				
				RemainderToDistribution = RemainderToDistribution - BalanceInHand;
				
				FillPropertyValues(FilterStructure1, SelectionSelectionNumber, "SelectionNumber");
				
				RowsArray = SelectionPortions.FindRows(FilterStructure1);
				For Each TableRow In RowsArray Do
					TableRow.WarehouseStockBalance = TableRow.WarehouseStockBalance + BalanceInHand;
				EndDo;
				
				If RemainderToDistribution = 0 Then
					Break;
				EndIf;	
				
			EndDo;	
			
		EndDo;	
		
	EndDo;	
	    	
EndProcedure	

&AtServer
Procedure ProcessSelectionOfAnalogues(Confirm = True)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	UsedMaterials.LineNumber AS LineNumber,
	|	UsedMaterials.Products AS Products,
	|	UsedMaterials.Characteristic AS Characteristic,
	|	UsedMaterials.Count AS Count,
	|	UsedMaterials.QuantityConfirmed AS QuantityConfirmed,
	|	UsedMaterials.OriginalLineNumber AS OriginalLineNumber
	|INTO UsedMaterials
	|FROM
	|	&UsedMaterials AS UsedMaterials
	|
	|INDEX BY
	|	Count
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Substitutes.LineNumber AS LineNumber,
	|	Substitutes.Products AS Products,
	|	Substitutes.Characteristic AS Characteristic,
	|	Substitutes.InterchangeableSubstitute AS InterchangeableSubstitute,
	|	Substitutes.LinkKeyPermission AS LinkKeyPermission,
	|	Substitutes.Count AS Count,
	|	Substitutes.WarehouseStockBalance AS WarehouseStockBalance,
	|	Substitutes.StockBalanceConfirmed AS StockBalanceConfirmed,
	|	Substitutes.Warehouse AS Warehouse,
	|	Substitutes.Resolution AS Resolution,
	|	Substitutes.ResolutionPresentation AS ResolutionPresentation,
	|	Substitutes.UnitOfMeasurePresentation AS UnitOfMeasurePresentation,
	|	Substitutes.ThisIsASubstitute AS ThisIsASubstitute
	|INTO Substitutes
	|FROM
	|	&Substitutes AS Substitutes
	|
	|INDEX BY
	|	Count
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UsedMaterials.LineNumber AS LineNumber,
	|	UsedMaterials.OriginalLineNumber AS OriginalLineNumber,
	|	UsedMaterials.Products AS Products,
	|	UsedMaterials.Characteristic AS Characteristic,
	|	UsedMaterials.Count AS Count,
	|	UsedMaterials.QuantityConfirmed AS QuantityConfirmed,
	|	UsedMaterials.Count - UsedMaterials.QuantityConfirmed AS QuantityToDistribution
	|FROM
	|	UsedMaterials AS UsedMaterials
	|WHERE
	|	UsedMaterials.Count > UsedMaterials.QuantityConfirmed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Substitutes.LineNumber AS LineNumber,
	|	Substitutes.Products AS Products,
	|	Substitutes.Characteristic AS Characteristic,
	|	Substitutes.InterchangeableSubstitute AS InterchangeableSubstitute,
	|	Substitutes.LinkKeyPermission AS LinkKeyPermission,
	|	Substitutes.Count AS Count,
	|	Substitutes.StockBalanceConfirmed - Substitutes.WarehouseStockBalance AS WarehouseStockBalance,
	|	Substitutes.Warehouse AS Warehouse,
	|	Substitutes.Resolution AS Resolution,
	|	Substitutes.ResolutionPresentation AS ResolutionPresentation,
	|	Substitutes.UnitOfMeasurePresentation AS UnitOfMeasurePresentation,
	|	Substitutes.ThisIsASubstitute AS ThisIsASubstitute
	|FROM
	|	Substitutes AS Substitutes
	|WHERE
	|	Substitutes.Count > 0";
	
	Query.SetParameter(
		"UsedMaterials", 
		UsedMaterials.Unload(
			, 
			"LineNumber, Products, Characteristic, Count, QuantityConfirmed, OriginalLineNumber"));
	
	Query.SetParameter(
		"Substitutes", 
		Substitutes.Unload(
			, 
			"LineNumber, Resolution, ResolutionPresentation, ThisIsASubstitute, Products, Characteristic, InterchangeableSubstitute, LinkKeyPermission,"
			+ " Count, WarehouseStockBalance, StockBalanceConfirmed, Warehouse, UnitOfMeasurePresentation"));
	
	ResultsArray = Query.ExecuteBatch();
	
	TableMaterials = ResultsArray[ResultsArray.UBound() - 1].Unload(); // See ProductionServer.ServiceStructureOfValueTable
	
	TableAnalogues = ResultsArray[ResultsArray.UBound()].Unload();  // See ProductionServer.ServiceStructureOfValueTable
	TableAnalogues.Indexes.Add("Products, Characteristic, ThisIsASubstitute");
	
	If Confirm Then
		ColumnNameQuantityReceiver      = "QuantityConfirmed";
		ColumnNameStockBalanceReceiver = "StockBalanceConfirmed";
		ColumnNameQuantitySource      = "Count";
		ColumnNameStockBalanceSource = "WarehouseStockBalance"; 
	Else
		ColumnNameQuantityReceiver      = "Count";
		ColumnNameStockBalanceReceiver = "WarehouseStockBalance";
		ColumnNameQuantitySource      = "QuantityConfirmed";
		ColumnNameStockBalanceSource = "StockBalanceConfirmed"; 
	EndIf;
	
	FilterStructure1 = New Structure("Products, Characteristic, ThisIsASubstitute");
	StructureOfPurificationOfAnalogues = New Structure("Count, TooltipIsReplaced", 0, ""); 
	
	If Confirm Then
		
		ConnectionKey = ";" 
				  + StrReplace(StrConcat(TableMaterials.UnloadColumn("OriginalLineNumber"), ";"), Chars.NBSp, "") 
				  + ";";
		
		MaximumSelectionNumber = MaximumSelectionNumber + 1;
		
		FilterStructure1.ThisIsASubstitute = False;
						
	EndIf;
	
	KeyTemplate = NStr("vi = ';%1;';
						|ru = ';%1;';
						|en = ';%1;'; fa = ';%1;';
						|it = ';%1;';
						|pl = ';%1;';
						|tr = ';%1;'");
	
	For Each TableRow In TableMaterials Do
		
		NewMaterials = UsedMaterials[TableRow.LineNumber - 1];
		
		NewMaterials[ColumnNameQuantityReceiver] = NewMaterials[ColumnNameQuantitySource];
			
		If Confirm Then
			
			FillPropertyValues(FilterStructure1, TableRow);
			
			QuantityToDistribution = TableRow.QuantityToDistribution;
			
			RowsArray = TableAnalogues.FindRows(FilterStructure1);
			RowsIndex = RowsArray.UBound();
			While RowsIndex > -1 Do
				
				RowsIndex = RowsIndex - 1;
				
				RowOfAnalogsTable = RowsArray[0];
				
				ServingQuantity = Min(QuantityToDistribution, RowOfAnalogsTable.Count);
				
				SelectionPortion = SelectionPortions.Add();
				FillPropertyValues(SelectionPortion, RowOfAnalogsTable,, "Count");
				FillPropertyValues(SelectionPortion, NewMaterials, "OriginalLineNumber");
				SelectionPortion.Count = ServingQuantity;
				SelectionPortion.SelectionNumber = MaximumSelectionNumber;
				SelectionPortion.ConnectionKey = StringFunctionsClientServer.SubstituteParametersToString(
					KeyTemplate, NewMaterials.OriginalLineNumber);
				
				RowOfAnalogsTable.Count = RowOfAnalogsTable.Count - ServingQuantity;
				If RowOfAnalogsTable.Count = 0 Then
					
					FillPropertyValues(Substitutes[RowOfAnalogsTable.LineNumber - 1], StructureOfPurificationOfAnalogues);
					
					TableAnalogues.Delete(RowOfAnalogsTable);
					RowsArray.Delete(0);
					
				EndIf;	
				
				QuantityToDistribution = QuantityToDistribution - ServingQuantity;
				If QuantityToDistribution = 0 Then
					Break;
				EndIf;	
				
			EndDo;	
			
		EndIf;	
			
	EndDo;
	
	ProductList_ = New Map;
	ModeIsNotIsolatedBalance = DisplayModeNotIsolatedBalance();
	
	For Each TableRow In TableAnalogues Do
		
		StringAnalogues = Substitutes[TableRow.LineNumber - 1];
		FillPropertyValues(StringAnalogues, StructureOfPurificationOfAnalogues);
		
		If StringAnalogues.ThisIsASubstitute
		   And ProductList_.Get(TableRow.Products) <> TableRow.Characteristic Then
			
			ProductList_.Insert(TableRow.Products, TableRow.Characteristic);
			
			FillPropertyValues(FilterStructure1, TableRow);
			
			RowsArray = Substitutes.FindRows(FilterStructure1);
			For Each StringAnalogues In RowsArray Do
				
				StringAnalogues[ColumnNameStockBalanceReceiver] = StringAnalogues[ColumnNameStockBalanceSource];
				
				If Not Confirm Then
					SetThereAreLeftoversFlag(StringAnalogues);
				EndIf;
				
			EndDo;	
			
		EndIf;
		
		If Confirm Then
			
			AmountOfAnalogToReplace = TableRow.Count;
			
			BalanceSelectionParameters = New Structure("Products, Characteristic, Warehouse");
			FillPropertyValues(BalanceSelectionParameters, TableRow);
				
			If BalanceDisplayMode = ModeIsNotIsolatedBalance Then
				BalanceSelectionParameters.Insert("Purpose", Catalogs.Assignments.EmptyRef());
			EndIf;
			
			ArrayOfLineNumbers = StrSplit(ConnectionKey, ";", False);
			
			For Each LineNumber In ArrayOfLineNumbers Do
				
				If AmountOfAnalogToReplace = 0 Then
					Break;
				EndIf;
				
				RowsOfReplacedMaterials = SelectionPortions.FindRows(
					New Structure("Resolution, SelectionNumber, OriginalLineNumber", TableRow.Resolution, MaximumSelectionNumber, LineNumber - 0));
				ArrayOfBalancesOfAnalogues = RemnantsOfAnalogues.FindRows(BalanceSelectionParameters);
				
				For Each StringOfReplacedMaterials In RowsOfReplacedMaterials Do
					
					If TableRow.InterchangeableSubstitute Then
						
						NumberOfAnaloguesAccordingToStandard = AmountOfAnalogToReplace;
						
					Else	
						
						EstimatedAmountOfAnalog = NumberOfAnaloguesByStandards(StringOfReplacedMaterials, TableRow.LineNumber);
						NumberOfAnaloguesAccordingToStandard = ?(EstimatedAmountOfAnalog = 0, AmountOfAnalogToReplace, EstimatedAmountOfAnalog);
						
					EndIf;
					
					If NumberOfAnaloguesAccordingToStandard > 0 Then
					
						For Each ArrayRow In ArrayOfBalancesOfAnalogues Do
						
							If ArrayRow.AvailableForInventoryAllocation = 0 Then
								Continue;
							EndIf;
							
							If ValueIsFilled(ArrayRow.Purpose)
							   And ArrayRow.Purpose <> Purpose Then
								Continue;	
							EndIf;
							
							QuantityToWriteOff = Min(AmountOfAnalogToReplace, ArrayRow.AvailableForInventoryAllocation, NumberOfAnaloguesAccordingToStandard);
							NumberOfAnaloguesAccordingToStandard = NumberOfAnaloguesAccordingToStandard - QuantityToWriteOff;
							AmountOfAnalogToReplace = AmountOfAnalogToReplace - QuantityToWriteOff;
							ArrayRow.AvailableForInventoryAllocation = ArrayRow.AvailableForInventoryAllocation - QuantityToWriteOff;
							
							SelectionPortion = SelectionPortions.Add();
							FillPropertyValues(SelectionPortion, TableRow,, "Count");
							SelectionPortion.Count = QuantityToWriteOff;
							SelectionPortion.SelectionNumber = MaximumSelectionNumber;
							SelectionPortion.ConnectionKey = StringFunctionsClientServer.SubstituteParametersToString(
								KeyTemplate, LineNumber);
							SelectionPortion.WithAssignment = ArrayRow.WithAssignment;
							SelectionPortion.Purpose = ArrayRow.Purpose;
							SelectionPortion.SelectionOverBalance = False;
							
							If AmountOfAnalogToReplace = 0 Or NumberOfAnaloguesAccordingToStandard = 0 Then
								Break;
							EndIf;
						
						EndDo;	
					
					EndIf;
					
				EndDo;
				
			EndDo;
			
			If AmountOfAnalogToReplace > 0 Then
				
				ConnectionKeyBalance = "";
				ThereIsUndistributedAmount = True;
				
				For Each LineNumber In ArrayOfLineNumbers Do
					
					If AmountOfAnalogToReplace = 0 Then
						ThereIsUndistributedAmount = False;
						Break;
					EndIf;
					
					RowsOfReplacedMaterials = SelectionPortions.FindRows(
						New Structure("Resolution, SelectionNumber, OriginalLineNumber", TableRow.Resolution, MaximumSelectionNumber, LineNumber - 0));
						
					StringLinkKey = StringFunctionsClientServer.SubstituteParametersToString(
						KeyTemplate, LineNumber);
						
					If IsBlankString(ConnectionKeyBalance) Then
						ConnectionKeyBalance = StringLinkKey;
					EndIf;
					
					For Each StringOfReplacedMaterials In RowsOfReplacedMaterials Do
					
						If TableRow.InterchangeableSubstitute Then
							
							QuantityToBeAccountedForByLine = AmountOfAnalogToReplace;
							
						Else
							
							PortionSelectionStructure = New Structure;
							PortionSelectionStructure.Insert("Resolution", TableRow.Resolution);
							PortionSelectionStructure.Insert("Products", TableRow.Products);
							PortionSelectionStructure.Insert("Characteristic", TableRow.Characteristic);
							PortionSelectionStructure.Insert("Warehouse", TableRow.Warehouse);
							PortionSelectionStructure.Insert("ConnectionKey", StringLinkKey);
							PortionSelectionStructure.Insert("ThisIsASubstitute", True);
							PortionSelectionStructure.Insert("SelectionNumber", MaximumSelectionNumber);
							
							DistributedAnalog = AmountOfAnaloguePerServing(PortionSelectionStructure);
							
							EstimatedAmountOfAnalog = NumberOfAnaloguesByStandards(StringOfReplacedMaterials, TableRow.LineNumber);
							NumberOfAnaloguesAccordingToStandard = ?(EstimatedAmountOfAnalog = 0, AmountOfAnalogToReplace, EstimatedAmountOfAnalog);
							
							QuantityToBeAccountedForByLine = NumberOfAnaloguesAccordingToStandard - DistributedAnalog;
						
						EndIf;
						
						If QuantityToBeAccountedForByLine > 0 Then
						
							SelectionPortion = SelectionPortions.Add();
							FillPropertyValues(SelectionPortion, TableRow,, "Count");
							SelectionPortion.Count = QuantityToBeAccountedForByLine;
							SelectionPortion.SelectionNumber = MaximumSelectionNumber;
							SelectionPortion.ConnectionKey = StringLinkKey;
							SelectionPortion.WithAssignment = False;
							SelectionPortion.Purpose = Catalogs.Assignments.EmptyRef();
							SelectionPortion.SelectionOverBalance = True;
							
							AmountOfAnalogToReplace = AmountOfAnalogToReplace - QuantityToBeAccountedForByLine;
							
							If AmountOfAnalogToReplace = 0 Then
								ThereIsUndistributedAmount = False;
								Break;
							EndIf;
						
						EndIf;
						
					EndDo;
					
				EndDo;
				
				If ThereIsUndistributedAmount Then
				
					SelectionPortion = SelectionPortions.Add();
					FillPropertyValues(SelectionPortion, TableRow,, "Count");
					SelectionPortion.Count = AmountOfAnalogToReplace;
					SelectionPortion.SelectionNumber = MaximumSelectionNumber;
					SelectionPortion.ConnectionKey = ConnectionKeyBalance;
					SelectionPortion.WithAssignment = False;
					SelectionPortion.Purpose = Catalogs.Assignments.EmptyRef();
					SelectionPortion.SelectionOverBalance = True;
				
				EndIf;
			
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Confirm Then
		UpdateHintsReplacementCapability();
	EndIf;	
	
EndProcedure

&AtServer
Function AmountOfAnaloguePerServing(FilterStructure1)

	SubstituteQuantity = 0;
	
	ServingArray = SelectionPortions.FindRows(FilterStructure1);
	
	For Each PortionString In ServingArray Do
		SubstituteQuantity = SubstituteQuantity + PortionString.Count;
	EndDo;
	
	Return SubstituteQuantity;

EndFunction

&AtServer
Function NumberOfAnaloguesByStandards(SelectionPortionLine, LineNumberAnalog)
	
	NumberOfAnaloguesAccordingToStandard = 0;
	ReplacedMaterial = SelectionPortionLine.Count;
	
	FilterStructure1 = New Structure("Resolution, Products, Characteristic, ThisIsASubstitute", 
		SelectionPortionLine.Resolution, SelectionPortionLine.Products, SelectionPortionLine.Characteristic, False);
	
	ArrayOfStandardsMaterial = Substitutes.FindRows(FilterStructure1);
	
	If ArrayOfStandardsMaterial.Count() > 0 Then
	
		For Each Line1_ In ArrayOfStandardsMaterial Do
		
			NumberOfSets = ProductionClientServer.CoefficientByStandard(
				Line1_.ControlMultiplier, ReplacedMaterial, Line1_.NormativeStandard, Line1_.PackageData);
				
			Break;
			
		EndDo;
		
		ArrayOfStandardsAnalog = Substitutes.FindRows(New Structure("LineNumber", LineNumberAnalog));
		
		For Each Line1_ In ArrayOfStandardsAnalog Do
			
			NumberOfAnaloguesAccordingToStandard = 
				CalculateAmountOfAnalogByCoefficient(Line1_.NormativeStandard, NumberOfSets, Line1_.PackageData);
				
			Break;
			
		EndDo;
	
	EndIf;

	Return NumberOfAnaloguesAccordingToStandard;
	
EndFunction

&AtServer
Function CalculateAmountOfAnalogByCoefficient(NormativeStandard, ConversionFactor_, PackageData)

	EstimatedQuantity = NormativeStandard * ConversionFactor_ * PackageData.Numerator / PackageData.Denominator;
			
	CurrentCount = Int(EstimatedQuantity);
	If EstimatedQuantity > CurrentCount Then
		CurrentCount = CurrentCount + Int((EstimatedQuantity - CurrentCount) * 1000) / 1000;
	EndIf;
	
	Return CurrentCount;

EndFunction 

&AtClientAtServerNoContext
Procedure FillInTotals(Form)
	
	TotalToReplace = 0;
	TotalReplaced = 0;
	
	Items = Form.Items;
	
	ArrayOfSelectedRows = Items.UsedMaterials.SelectedRows;
	For Each SelectedRow In ArrayOfSelectedRows Do
		
		CurrentRow = Form.UsedMaterials.FindByID(SelectedRow);
		
		TotalToReplace = TotalToReplace + CurrentRow.ToReplace - CurrentRow.QuantityConfirmed;
		TotalReplaced = TotalReplaced + CurrentRow.Count - CurrentRow.QuantityConfirmed;
		
	EndDo;
	
	Form.TotalToReplace = TotalToReplace; 
	Form.TotalReplaced = TotalReplaced;
	Form.TotalLeftToReplace = TotalToReplace - TotalReplaced;
	
EndProcedure	

&AtServer
Function SelectionData_2(Products, Characteristic, LineNumbers)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SelectionPortions.SelectionNumber AS SelectionNumber,
	|	SelectionPortions.OriginalLineNumber AS OriginalLineNumber,
	|	SelectionPortions.Products AS Products,
	|	SelectionPortions.Characteristic AS Characteristic,
	|	SelectionPortions.Count AS Count
	|INTO SelectionPortions
	|FROM
	|	&SelectionPortions AS SelectionPortions
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	OriginalLineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectionPortions.SelectionNumber AS SelectionNumber,
	|	CAST(SelectionPortions.Products AS Catalog.Products).UnitOfMeasure.Presentation AS UnitOfMeasure,
	|	SUM(SelectionPortions.Count) AS Count
	|FROM
	|	SelectionPortions AS SelectionPortions
	|WHERE
	|	SelectionPortions.Products = &Products
	|	AND SelectionPortions.Characteristic = &Characteristic
	|	AND SelectionPortions.OriginalLineNumber IN(&ArrayOfLineNumbers)
	|
	|GROUP BY
	|	SelectionPortions.SelectionNumber,
	|	SelectionPortions.Products
	|
	|ORDER BY
	|	SelectionNumber";
	
	Query.SetParameter(
		"SelectionPortions",
		SelectionPortions.Unload(, "SelectionNumber, OriginalLineNumber, Products, Characteristic, Count"));
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("ArrayOfLineNumbers", LineNumbers);
	
	Result = Query.Execute();
	
	ListOfSelections = New ValueList;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		ListOfSelections.Add(
			Selection.SelectionNumber, 
			StrTemplate("%1 %2 %3", StrTemplate(NStr("vi = 'Đã thay thế%1';
													|ru = 'Заменено%1';
													|en = 'Replaced%1'; fa = 'Replaced%1';
													|it = 'Sostituito%1';
													|pl = 'Replaced%1';
													|tr = 'Değiştirildi%1'"), " "), Selection.Count, Selection.UnitOfMeasure));
		
	EndDo;
	
	If Items.Pages.CurrentPage = Items.AnalogsPage
	   And Substitutes.Count() > Substitutes.FindRows(New Structure("Count", 0)).Count() Then
		ListOfSelections.Add(-1, NStr("vi = 'Hiện tại';
										|ru = 'Текущая';
										|en = 'Current'; fa = 'فعلی';
										|it = 'Corrente';
										|pl = 'Current';
										|tr = 'Mevcut'"));    	
	EndIf;   
	
	Return ListOfSelections;
	
EndFunction

&AtServer
Function GetTotalNumberOfAnalogues(Products, Characteristic, ThisIsASubstitute)
	
	Count = 0;
	
	FilterStructure1 = New Structure("Products, Characteristic, ThisIsASubstitute", 
									   Products, Characteristic, ThisIsASubstitute);
	
	RowsArray = Substitutes.FindRows(FilterStructure1);
	For Each TableRow In RowsArray Do
		Count = Count + TableRow.Count;	
	EndDo;	
	
	Return Count;
	
EndFunction

&AtServer
Function GetTotalAmountOfMaterialRequired(Products, Characteristic)
	
	Count = 0;
	
	FilterStructure1 = New Structure("Products, Characteristic", Products, Characteristic);
	
	RowsArray = UsedMaterials.FindRows(FilterStructure1);
	For Each TableRow In RowsArray Do
		Count = Count + TableRow.ToReplace - TableRow.QuantityConfirmed;
	EndDo;
	
	Return Count;
	
EndFunction	

&AtServer
Procedure UpdateHintsReplacementCapability()
	
	FilterStructure1 = New Structure("Products, Characteristic, ThisIsASubstitute");
	FillPropertyValues(FilterStructure1, UsedMaterials.FindByID(Items.UsedMaterials.SelectedRows[0]));
	FilterStructure1.ThisIsASubstitute = False;
	
	RowsArray = Substitutes.FindRows(FilterStructure1);
	
	FilterStructure1.Insert("IsBalance", True);
	SetHintForLeftovers(
		FilterStructure1.Products, FilterStructure1.Characteristic, Substitutes.FindRows(FilterStructure1).Count() > 0);
	
	ProcessedProducts = New Map;
	ProcessedProducts.Insert(FilterStructure1.Products, FilterStructure1.Characteristic);
	
	For Each StringAnalogues In RowsArray Do
		
		PermitSelectionStructure = New Structure("Resolution, ThisIsASubstitute");
		FillPropertyValues(PermitSelectionStructure, StringAnalogues);
		
		ArrayOfPermissionStrings = Substitutes.FindRows(PermitSelectionStructure);
		For Each TableRow In ArrayOfPermissionStrings Do
			
			If TableRow.Characteristic = ProcessedProducts.Get(TableRow.Products) Then
				Continue;
			EndIf;
			
			FillPropertyValues(FilterStructure1, TableRow, "Products, Characteristic");
			
			SetHintForLeftovers(
				TableRow.Products, TableRow.Characteristic, Substitutes.FindRows(FilterStructure1).Count() > 0);
				
			ProcessedProducts.Insert(TableRow.Products, TableRow.Characteristic);
			
		EndDo;
		
	EndDo;
		
EndProcedure

&AtServer
Procedure SetHintForLeftovers(Products, Characteristic, IsBalance)
	
	If Not GeneralParameters.ShowBalance Then
		Return;
	EndIf;
	
	HintThereAreLeftovers = NStr("vi = 'có số dư';
								|ru = 'есть остатки';
								|en = 'there is balance'; fa = 'there is balance';
								|it = 'ci sono residui';
								|pl = 'są pozostałości';
								|tr = 'bakiye mevcut'");
	HintNoLeftovers = NStr("vi = 'không có số dư';
							|ru = 'нет остатков';
							|en = 'no balance'; fa = 'no balance';
							|it = 'non ci sono residui';
							|pl = 'brak pozostałości';
							|tr = 'bakiye mevcut değil'");
	
	ReplacementHint = ?(IsBalance, HintNoLeftovers, HintThereAreLeftovers);
	CurrentHint = ?(IsBalance, HintThereAreLeftovers, HintNoLeftovers);
	
	FilterStructure1 = New Structure("Products, Characteristic", Products, Characteristic);
	
	RowsArray = UsedMaterials.FindRows(FilterStructure1);
	If StrFind(RowsArray[0].TipReplacementOption, ReplacementHint) > 0 Then
		
		For Each TableRow In RowsArray Do
			
			TableRow.TipReplacementOption = 
				StrReplace(TableRow.TipReplacementOption, ReplacementHint, CurrentHint);
				
		EndDo;
			
	EndIf;	
	
EndProcedure	

&AtClientAtServerNoContext
Function ThereAreInvalidPermissions(Form)
	
	Items = Form.Items;
	
	If Items.UsedMaterials.CurrentRow = Undefined Then
		Return False;
	EndIf;
	
	CurrentData = Form.UsedMaterials.FindByID(Items.UsedMaterials.CurrentRow);
	If CurrentData = Undefined Then
		Return False;
	EndIf;
	
	SelectionBasedOnInvalidPermissions = New Structure("LineNumber");
	FillPropertyValues(SelectionBasedOnInvalidPermissions, CurrentData);
	
	RowsArray = Form.InvalidPermissions.FindRows(SelectionBasedOnInvalidPermissions);
	NumberOfRowsFound = RowsArray.Count();
	If NumberOfRowsFound = 0 Then
	
		SetPermissionAvailableFlag(Form);
	
		RowsArray = Form.InvalidPermissions.FindRows(SelectionBasedOnInvalidPermissions);
		NumberOfRowsFound = RowsArray.Count();
	
	EndIf;
	
	Return NumberOfRowsFound > 1 Or ValueIsFilled(RowsArray[0].Resolution);
	
EndFunction

#EndRegion

#EndRegion

#Region Appearance

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	SetConditionalAppearanceMaterials();
	
	SetConditionalAppearanceAnalogues();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceMaterials()
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "UsedMaterialsCharacteristic", "UsedMaterials.ItemVariantsAreUsed");
	
	// Materials: Color Text
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterials.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsedMaterials.ThereAreSubstituteMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsedMaterials.ToReplace");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("UsedMaterials.Count");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//Quantity: Font
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsCount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsedMaterials.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Font", New Font(,, True));
	
	//Quantity: Text Color
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsCount.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalReplaced.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsedMaterials.ToReplace");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("UsedMaterials.Count");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceAnalogues()
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "SubstitutesCharacteristic", "Substitutes.ItemVariantsAreUsed");
	
	//Analogs: Visibility
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Substitutes.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubstitutesProductsUnitOfMeasure.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Substitutes.ThisIsASubstitute");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//Resolution Representation: Text color, Font
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalogsResolutionPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Substitutes.ResolutionPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Font", New Font(,,,, True));
	
	//Hint Changed: Text color, Font
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalogsHintReplaced.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Substitutes.TooltipIsReplaced");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Font", New Font(StyleFonts.SmallTextFont,,, True));
	
	//The result is changed: Font
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalReplaced.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalReplaced");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Font", New Font(,, True));
	
EndProcedure	

&AtServer
Procedure SetInitialPageLayout(PageName, ShowLeftoversFlag, ConsiderInventory)
	
	If Not ShowLeftoversFlag Then
		Items.SubstitutesSelectionMode.Visible = ShowLeftoversFlag;
		Items.BalanceDisplayMode.Visible = ShowLeftoversFlag;
		Items.SelectionModeWarehouse.Visible = ShowLeftoversFlag;
		Items.AnalogSelectionWarehouse.Visible = ShowLeftoversFlag;
		Items.TheWritingStep2.Visible = Not ShowLeftoversFlag;
	EndIf;
	
	Items.UsedMaterialsWarehouse.Visible = ShowLeftoversFlag;
		
	Items.SubstitutesIsBalance.Visible = ShowLeftoversFlag;
	Items.SubstitutesWarehouseStockBalance.Visible = ShowLeftoversFlag;
	Items.SubstitutesWarehouse.Visible = ShowLeftoversFlag;
	Items.SubstitutesRemainingBalanceInOtherWarehouses.Visible = ShowLeftoversFlag;
	
	SetHyperlinkTitleSeeAlso(PageName);
	
	Items.ReplacementSource.Visible = ?(PageName = "UsedMaterials", ShowLeftoversFlag And ConsiderInventory, False);
	Items.ReplacementSourceOnTheAnalogsPage.Visible = ?(PageName = "Substitutes",
															ShowLeftoversFlag And ConsiderInventory,
															False);
	
	If PageName = "Substitutes" Then
		
		Items.TheWritingStep2.Title = NStr("vi = 'Lựa chọn các chất tương tự';
											|ru = 'Подбор аналогов';
											|en = 'Pick substitutes'; fa = 'انتخاب جایگزین‌ها';
											|it = 'Selezione degli analoghi';
											|pl = 'Dobór odpowiedników';
											|tr = 'İkamelerin seçimi'");
		Items.PermissionValidityDate.Visible = True;
		
		SetPermissionsPresentation(UsedMaterials[0].Products, UsedMaterials[0].Characteristic);
		
		Items.PagesFooter.CurrentPage = Items.RemainingMaterialsPage;
		
	EndIf;
	
	SetCurrentPage(ThisObject, PageName);
	
	If PageName = "Substitutes" Then
		
		StringMaterial = UsedMaterials[0];
		If StringMaterial.WithAssignment Then
		
			BalanceDisplayMode = DisplayModeSeparateBalance();
			
		Else
			
			BalanceDisplayMode = 0;
		
		EndIf;
		
		If Not ValueIsFilled(SelectionModeWarehouse) Then
			SelectionModeWarehouse = ModeOfWarehousesAccordingToSecurityScheme();
		EndIf;
		
		FillInBalanceInWarehouse(ThisObject, SeparatePosition, Purpose);
		SetAvailabilityOfBalanceDisplayMode(ThisObject);
		
	EndIf;
				
EndProcedure	

&AtClientAtServerNoContext
Procedure SetCurrentPage(Form, PageName, ConnectionKey = Undefined, Mode = 0)
	
	Items = Form.Items;
	
	If PageName = "UsedMaterials" Then
		Items.Pages.CurrentPage = Items.PageMaterials;
	Else
		Items.Pages.CurrentPage = Items.AnalogsPage;
	EndIf;
	
	If PageName = "Substitutes" Then
		SubmitMaterialsOnPage(Form);
		SetPermissionAvailableFlag(Form);
		SetSelectionByAvailableAnalogues(Items[PageName].RowFilter, ConnectionKey, Mode);
		InstallInscriptionLackOfAnalogues(Form);
		SetReportHint(Form);
	EndIf;	
	
EndProcedure

&AtClientAtServerNoContext
Procedure SubmitMaterialsOnPage(Form)
	
	Items = Form.Items;
	
	CurrentRowData = Form.UsedMaterials.FindByID(Items.UsedMaterials.CurrentRow);
	
	Form.ProductsPresentation = CurrentRowData.ProductsPresentation;
	
	If CurrentRowData.SupplyAssignment <> PredefinedValue("Catalog.Assignments.EmptyRef") Then
		Form.Purpose = CurrentRowData.SupplyAssignment;
	Else	
		Form.Purpose = CurrentRowData.Purpose;
	EndIf;
	DestinationVisibility = ValueIsFilled(Form.Purpose);
	Items.Purpose.Visible = DestinationVisibility;
	Form.SeparatePosition = CurrentRowData.WithAssignment;
	
	If ValueIsFilled(CurrentRowData.Characteristic) Then
		Form.ProductsPresentation = 
			Form.ProductsPresentation + " / " + CurrentRowData.CharacteristicPresentation;
	EndIf;	
	
	FillInTotals(Form);
			
EndProcedure	

&AtClientAtServerNoContext
Procedure SetPermissionAvailableFlag(Form)
	
	Items = Form.Items;
	
	CurrentData = Form.UsedMaterials.FindByID(Items.UsedMaterials.CurrentRow);
	
	SelectionBasedOnInvalidPermissions = New Structure("LineNumber");
	FillPropertyValues(SelectionBasedOnInvalidPermissions, CurrentData);
	
	RowsArray  = Form.InvalidPermissions.FindRows(SelectionBasedOnInvalidPermissions);
	RowIndex = RowsArray.UBound();
	While RowIndex > -1 Do
		Form.InvalidPermissions.Delete(Form.InvalidPermissions[RowIndex]);
		RowIndex = RowIndex - 1;
	EndDo;
	
	RowsArray = Form.Substitutes.FindRows(New Structure("PermissionIsAvailable", False));
	For Each StringAnalogues In RowsArray Do
		StringAnalogues.PermissionIsAvailable = True;
	EndDo;
	
	CacheRemainsToBeReplaced = New Map;
	
	TotalLeftToReplace = CurrentData.ToReplace - CurrentData.Count;
	
	FilterStructure1 = New Structure("Products, Characteristic, ControlMultiplier, ThisIsASubstitute, InterchangeableSubstitute");
	FillPropertyValues(FilterStructure1, CurrentData);
	FilterStructure1.ControlMultiplier = True;
	FilterStructure1.ThisIsASubstitute = False;
	FilterStructure1.InterchangeableSubstitute = False;
	
	RowsArray = Form.Substitutes.FindRows(FilterStructure1);
	For Each StringAnalogues In RowsArray Do
		
		PermissionIsAvailable = StringAnalogues.NormativeStandard <= TotalLeftToReplace Or TotalLeftToReplace = 0;
		
		If PermissionIsAvailable Then
			
			ArrayOfStringsResolution = Form.Substitutes.FindRows(New Structure("Resolution, ThisIsASubstitute", StringAnalogues.Resolution, False));
			For Each StringResolution In ArrayOfStringsResolution Do
				
				If StringResolution.Products = StringAnalogues.Products 
				   And StringResolution.Characteristic = StringAnalogues.Characteristic Then
				   	Continue;
				EndIf;
				
				MaterialKey = StrTemplate("%1 %2", 
											StringResolution.Products.UUID(), 
											StringResolution.Characteristic.UUID());
											
				QuantityLeftToReplace = CacheRemainsToBeReplaced.Get(MaterialKey);
											
				If QuantityLeftToReplace = Undefined Then
					
					QuantityLeftToReplace = 0;
					
					SelectionStructureMaterials = New Structure("Products, Characteristic");
					FillPropertyValues(SelectionStructureMaterials, StringResolution);
					
					ArrayOfStringsMaterials = Form.UsedMaterials.FindRows(SelectionStructureMaterials);
					For Each NewMaterials In ArrayOfStringsMaterials Do
						QuantityLeftToReplace = QuantityLeftToReplace + NewMaterials.ToReplace - NewMaterials.Count;
					EndDo;
					
					CacheRemainsToBeReplaced.Insert(MaterialKey, QuantityLeftToReplace);
					
				EndIf;
				
				PermissionIsAvailable = StringResolution.NormativeStandard <= QuantityLeftToReplace Or QuantityLeftToReplace = 0;
				If Not PermissionIsAvailable Then
					Break;
				EndIf;
					
			EndDo;
			
		EndIf;
		
		If Not PermissionIsAvailable Then
			
			TableRow = Form.InvalidPermissions.Add();
			FillPropertyValues(TableRow, SelectionBasedOnInvalidPermissions);
			FillPropertyValues(TableRow, StringAnalogues, "Resolution");
			
			ArrayOfStringsResolution = Form.Substitutes.FindRows(New Structure("Resolution", StringAnalogues.Resolution));
			For Each StringResolution In ArrayOfStringsResolution Do
				StringResolution.PermissionIsAvailable = False;	
			EndDo;
			
		EndIf;
		
	EndDo;
	
	// A line with an empty resolution is a sign of processing this line of materials
	RowsByFilter = Form.InvalidPermissions.FindRows(SelectionBasedOnInvalidPermissions);
	
	If RowsByFilter.Count() = 0 Then
	
		TableRow = Form.InvalidPermissions.Add();
		FillPropertyValues(TableRow, SelectionBasedOnInvalidPermissions);
	
	EndIf;
	
EndProcedure	

&AtClientAtServerNoContext
Procedure SetSelectionByAvailableAnalogues(Filter, ConnectionKey = Undefined, Mode = 0)

	FilterStructure1 = New Structure;
	
	FilterStructure1.Insert("PermissionIsAvailable", True);
	FilterStructure1.Insert("AnalogueCoincidesWithMaterial", False);
	
	If ConnectionKey <> Undefined Then
		FilterStructure1.Insert("LinkKeyPermission", ConnectionKey);
	EndIf;	
	
	If Mode = 1 Then
		FilterStructure1.Insert("IsBalanceInternal", True);	
	EndIf;
		
	Filter = New FixedStructure(FilterStructure1);
	
EndProcedure

&AtServer
Procedure SetPermissionsPresentation(Products, Characteristic)
	
	FilterStructure1 = New Structure("Products, Characteristic, ThisIsASubstitute", Products, Characteristic, False);
	SelectionStructureResolution = New Structure("DisplayPermission, ThisIsASubstitute, Resolution", True, True);
	
	RowsArray = Substitutes.FindRows(FilterStructure1);
	For Each TableRow In RowsArray Do
		
		FillPropertyValues(SelectionStructureResolution, TableRow, "Resolution");
		
		FillPropertyValues(
			Substitutes.FindRows(SelectionStructureResolution)[0], TableRow, "ResolutionPresentation");
		
	EndDo;	
	
EndProcedure	

&AtClientAtServerNoContext
Procedure InstallInscriptionLackOfAnalogues(Form)

	LabelText = "";
	
	If Form.Substitutes.Count() = 0 Then
		LabelText = NStr("vi = 'Không tìm thấy sự tương tự cho ngày được chỉ định';
						|ru = 'Аналоги на указанную дату не найдены';
						|en = 'Substitutes are not found for the specified date'; fa = 'Substitutes are not found for the specified date';
						|it = 'Non sono stati trovati analoghi per la data indicata';
						|pl = 'Odpowiedniki w określonym terminie nie zostały znalezione';
						|tr = 'Belirtilen tarih için ikameler bulunmadı'");
	ElsIf Form.SelectionPortions.Count() = 0 
	        And Form.Substitutes.Count() = Form.Substitutes.FindRows(New Structure("Count", 0)).Count() Then
		LabelText = NStr("vi = 'Không có tương tự được chọn';
						|ru = 'Ни один аналог не выбран';
						|en = 'No substitutes are selected'; fa = 'No substitutes are selected';
						|it = 'Nessun analogo selezionato';
						|pl = 'Żaden odpowiednik nie jest wybrany';
						|tr = 'Herhangi bir ikame seçilmedi'");
	EndIf;
	
	Form.Items.TheLabelLackOfAnalogues.Title = LabelText;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetReportHint(Form)

	Items = Form.Items;
	
	HyperlinkFragments = New Array;
	HyperlinkFragments.Add(NStr("vi = 'Xem thêm:';
								|ru = 'См. также:';
								|en = 'See also:'; fa = 'همچنین ببینید:';
								|it = 'Vedi anche:';
								|pl = 'Zob. także:';
								|tr = 'Ayrıca bk.:'"));
	
	HyperlinkFragments.Add(" ");
	
	PresentingHyperlinks = NStr("vi = 'Số dư và tính khả dụng của vật tư tương tự trong kho chính;';
								|ru = 'Остатки и доступность аналогов на основном складе;';
								|en = 'Substitute availability in main warehouse'; fa = 'Substitute availability in main warehouse';
								|it = 'Substitute availability in main warehouse';
								|pl = 'Substitute availability in main warehouse';
								|tr = 'İkamelerin ana ambardaki bakiyeleri ve erişilebilirliği;'");
	HyperlinkFragments.Add(
		New FormattedString(PresentingHyperlinks,,,, "BalancesAndAvailabilityOfAnalogues"));
	
	HyperlinkFragments.Add(" ");
	
	PresentingHyperlinks = NStr("vi = 'Số dư và tính khả dụng của vật tư tương tự trong tất cả các kho;';
								|ru = 'Остатки и доступность аналогов на всех складах;';
								|en = 'Substitute availability in all warehouses'; fa = 'Substitute availability in all warehouses';
								|it = 'Substitute availability in all warehouses';
								|pl = 'Substitute availability in all warehouses';
								|tr = 'İkamelerin tüm ambarlardaki bakiyeleri ve erişilebilirliği;'");
	HyperlinkFragments.Add(
		New FormattedString(PresentingHyperlinks,,,, "BalancesAndAvailabilityOfAnaloguesInAllWarehouses"));
		
	HyperlinkFragments.Add(" ");
	
	PresentingHyperlinks = NStr("vi = 'Số dư và tính khả dụng của nguyên vật liệu, cũng như các vật tư tương tự của chúng tại tất cả các kho;';
								|ru = 'Остатки и доступность материалов и их аналогов на всех складах;';
								|en = 'Material and substitute availability in all warehouses'; fa = 'Material and substitute availability in all warehouses';
								|it = 'Material and substitute availability in all warehouses';
								|pl = 'Material and substitute availability in all warehouses';
								|tr = 'Malzemelerin ve İkamelerin tüm ambarlardaki bakiyeleri ve erişilebilirliği;'");
	HyperlinkFragments.Add(
		New FormattedString(PresentingHyperlinks,,,, "BalancesAndAvailabilityOfMaterialsAndAnaloguesInAllWarehouses"));
	
	HyperlinkElement = Items.SeeAlsoAnaloguesAvailability;
 
	HyperlinkElement.Title = New FormattedString(HyperlinkFragments);

EndProcedure

&AtServer
Procedure SetHyperlinkTitleSeeAlso(PageName)
	
	ThereAreInvalidPermissions = ThereAreInvalidPermissions(ThisObject);
	ThereAreInvalidPermissionsBeforeTheChange = ThereAreInvalidPermissions;
	
	If PageName = "UsedMaterials" Then
		HyperlinkItemHasInvalidPermissions = Items.SeeAlsoMaterialsInvalidPermissions;
	Else
		HyperlinkItemHasInvalidPermissions = Items.SeeAlsoAnaloguesInvalidPermissions;
	EndIf;
 
	HyperlinkItemHasInvalidPermissions.Visible = ThereAreInvalidPermissions;
	
EndProcedure	

&AtClientAtServerNoContext
Procedure FillInBalanceInWarehouse(Form, WithAssignment, Purpose)

	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("ThisIsASubstitute", True);
	
	RowsArray = Form.Substitutes.FindRows(TheStructureOfTheSearch);
	For Each TSRow In RowsArray Do
		
		TSRow.WarehouseStockBalance = 0;
		TSRow.StockBalanceConfirmed = 0;
		TSRow.RemainingBalanceInOtherWarehouses = 0;
		
	EndDo;
	
	EmptyAssignment = PredefinedValue("Catalog.Assignments.EmptyRef");
	TheStructureOfTheSearch = New Structure("Products, Characteristic, Warehouse, ThisIsASubstitute");
	TheStructureOfTheSearch.ThisIsASubstitute = True;
	SeparateModeBalance = DisplayModeSeparateBalance();
	ModeIsNotIsolatedBalance = DisplayModeNotIsolatedBalance();
	
	If Form.BalanceDisplayMode <> SeparateModeBalance Then
	
		BalancesForEmptyDestination = Form.RemnantsOfAnalogues.FindRows(New Structure("Purpose", EmptyAssignment));
		ArrayOfBalancesOfAnalogues = New Array;
	
		For Each RemainderLine_ In BalancesForEmptyDestination Do
			
			FillPropertyValues(TheStructureOfTheSearch, RemainderLine_);
			ArrayOfBalancesOfAnalogues = Form.Substitutes.FindRows(TheStructureOfTheSearch);
			
			For Each StringAnalog In ArrayOfBalancesOfAnalogues Do
				StringAnalog.WarehouseStockBalance = RemainderLine_.AvailableForInventoryAllocation;
				StringAnalog.StockBalanceConfirmed = RemainderLine_.AvailableForInventoryAllocation;
				StringAnalog.RemainingBalanceInOtherWarehouses = BalanceOfItemsInOtherWarehouses(
					Form, TheStructureOfTheSearch.Products, TheStructureOfTheSearch.Characteristic, EmptyAssignment);
				StringAnalog.IsBalance = RemainderLine_.AvailableForInventoryAllocation > 0;
			EndDo;
			
		EndDo;
	
	EndIf;
	
	AvailabilityOfBalanceMode = WithAssignment Or ValueIsFilled(Purpose);
	
	If Purpose <> EmptyAssignment
	   And Form.BalanceDisplayMode <> ModeIsNotIsolatedBalance Then
	
		BalancesAsIntended = Form.RemnantsOfAnalogues.FindRows(New Structure("Purpose", Purpose));
		FilterParameters = New Structure("Products, Characteristic, Warehouse, ThisIsASubstitute");
		FilterParameters.ThisIsASubstitute = True;
			
		For Each RemainderLine_ In BalancesAsIntended Do
		
			FillPropertyValues(FilterParameters, RemainderLine_);
			ArrayOfBalancesOfAnalogues = Form.Substitutes.FindRows(FilterParameters);
			
			For Each StringAnalog In ArrayOfBalancesOfAnalogues Do
					
				DetachedBalance = RemainderLine_.AvailableForInventoryAllocation;
				StringAnalog.WarehouseStockBalance = StringAnalog.WarehouseStockBalance + DetachedBalance;
				StringAnalog.StockBalanceConfirmed = StringAnalog.StockBalanceConfirmed + DetachedBalance;
				
				RemainingBalanceInOtherWarehouses = BalanceOfItemsInOtherWarehouses(
					Form, FilterParameters.Products, FilterParameters.Characteristic, Purpose);
				StringAnalog.RemainingBalanceInOtherWarehouses = StringAnalog.RemainingBalanceInOtherWarehouses + RemainingBalanceInOtherWarehouses;
				
				If Not StringAnalog.IsBalance Then
					StringAnalog.IsBalance = DetachedBalance > 0;
				Else
					StringAnalog.IsBalance = StringAnalog.WarehouseStockBalance > 0;
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	If AvailabilityOfBalanceMode
	   And Purpose = EmptyAssignment Then
	
		AvailabilityOfBalanceMode = False;	
	
	EndIf;
	
	Form.AvailabilityOfBalanceMode = AvailabilityOfBalanceMode;
	Form.RemnantsOfAnalogues.Sort("WithAssignment DESC");
	SetAvailabilityOfBalanceDisplayMode(Form);

EndProcedure

&AtClientAtServerNoContext
Function DisplayModeSeparateBalance()

	Return 1;

EndFunction

&AtClientAtServerNoContext
Function DisplayModeNotIsolatedBalance()

	Return 2;

EndFunction

&AtClientAtServerNoContext
Procedure SetAvailabilityOfBalanceDisplayMode(Form)
	
	ThereIsSelectedQuantity = ThereIsQuantityForSelectedMaterials(Form);
	FieldAvailability = Form.AvailabilityOfBalanceMode And Not ThereIsSelectedQuantity;
	AvailabilityOfWarehouseSelectionFields = Not ThereIsSelectedQuantity;
	YouCanSpecifyWarehouse = Not Form.SelectionFromWarehouseFromFormParameters And Not Form.GeneralParameters.DetailsMode;
	
	Items = Form.Items;
	
	Items.BalanceDisplayMode.Enabled = FieldAvailability;
	Items.SelectionModeWarehouse.Visible = YouCanSpecifyWarehouse;
	Items.AnalogSelectionWarehouse.Visible = YouCanSpecifyWarehouse;
	Items.SelectionModeWarehouse.Enabled = YouCanSpecifyWarehouse And AvailabilityOfWarehouseSelectionFields;
	Items.AnalogSelectionWarehouse.Enabled = YouCanSpecifyWarehouse And AvailabilityOfWarehouseSelectionFields;
	Items.AnalogSelectionWarehouse.Visible = YouCanSpecifyWarehouse And Form.SelectionModeWarehouse = ManuallySpecifiedWarehouseMode();
	
	If Not FieldAvailability And Not ThereIsSelectedQuantity Then
		Form.BalanceDisplayMode = DisplayModeNotIsolatedBalance();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ThereIsQuantityForSelectedMaterials(Form)

	Items = Form.Items;
	UsedMaterials = Form.UsedMaterials;
	ArrayOfSelectedRows = Items.UsedMaterials.SelectedRows;
	
	ThereIsSelectedQuantity = False;
	
	For Each RowID In ArrayOfSelectedRows Do
			
		CurrentRow = UsedMaterials.FindByID(RowID);
		
		If CurrentRow.Count > 0 Then
			ThereIsSelectedQuantity = True;
			Break;
		EndIf;
		
	EndDo;
	
	Return ThereIsSelectedQuantity;

EndFunction

&AtClientAtServerNoContext
Function BalanceOfItemsInOtherWarehouses(Form, Products, Characteristic, Purpose)
	
	SearchForBalances = New Structure("Products, Characteristic, Purpose", Products, Characteristic, Purpose);
	
	ArrayOfBalances = Form.BalancesOfAnaloguesInOtherWarehouses.FindRows(SearchForBalances);
	
	Balance = 0;
	
	For Each SpecificationRow In ArrayOfBalances Do
	
		Balance = Balance + SpecificationRow.AvailableForInventoryAllocation;
	
	EndDo;
	
	Return Balance;

EndFunction

&AtClient
Procedure ProcessFormONChangingWarehouseSelection()
	
	If SelectionModeWarehouse = WarehouseModeAccordingToDocument() Then
		SelectionWarehouse = Items.UsedMaterials.CurrentData.Warehouse;
	ElsIf SelectionModeWarehouse = ModeOfWarehousesAccordingToSecurityScheme() Then
		SelectionWarehouse = Undefined;
	ElsIf SelectionModeWarehouse = ManuallySpecifiedWarehouseMode() Then
		SelectionWarehouse = AnalogSelectionWarehouse;
	Else
		SelectionWarehouse = Undefined;
	EndIf;
	
	For Each TableRow In Substitutes Do
	
		If TableRow.ThisIsASubstitute And Not TableRow.ThisIsWork Then
			TableRow.Warehouse = ?(SelectionWarehouse = Undefined, TableRow.WarehouseAccordingToSecurityScheme, SelectionWarehouse);
		EndIf;
	
	EndDo;	

EndProcedure

&AtClientAtServerNoContext
Function WarehouseModeAccordingToDocument()

	Return 1;

EndFunction

&AtClientAtServerNoContext
Function ModeOfWarehousesAccordingToSecurityScheme()

	Return 2;

EndFunction

&AtClientAtServerNoContext
Function ManuallySpecifiedWarehouseMode()

	Return 3;

EndFunction

&AtServer
Procedure UpdateBalanceAfterWarehouseChange(WithAssignment, Purpose)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	InventoryTable.Products AS Products,
	|	InventoryTable.Characteristic AS Characteristic,
	|	InventoryTable.Warehouse AS Warehouse,
	|	InventoryTable.Purpose AS Purpose,
	|	InventoryTable.WithAssignment AS WithAssignment,
	|	InventoryTable.Count AS Count
	|INTO InventoryTransferred
	|FROM
	|	&Inventories AS InventoryTable
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inventories.Products AS Products,
	|	Inventories.Characteristic AS Characteristic,
	|	Inventories.Warehouse AS Warehouse,
	|	Inventories.Purpose AS Purpose,
	|	SUM(Inventories.Count) AS Count
	|INTO InventoryTable
	|FROM
	|	InventoryTransferred AS Inventories
	|
	|GROUP BY
	|	Inventories.Products,
	|	Inventories.Characteristic,
	|	Inventories.Warehouse,
	|	Inventories.Purpose
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 0
	|	NULL AS Products,
	|	NULL AS Characteristic,
	|	NULL AS Warehouse,
	|	NULL AS Purpose,
	|	NULL AS Count
	|INTO TableOfReserves
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfAnalogues.Products AS Products,
	|	TableOfAnalogues.Characteristic AS Characteristic,
	|	TableOfAnalogues.Warehouse AS Warehouse,
	|	TableOfAnalogues.Purpose AS Purpose
	|INTO SelectionOfBalanceAnalogues
	|FROM
	|	&TableOfAnalogues AS TableOfAnalogues
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfAnalogues.Products AS Products,
	|	TableOfAnalogues.Characteristic AS Characteristic,
	|	TableOfAnalogues.Warehouse AS Warehouse,
	|	TableOfAnalogues.Purpose AS Purpose,
	|	TableOfAnalogues.Count AS Count
	|INTO SelectedAnalogues
	|FROM
	|	&SelectedAnalogues AS TableOfAnalogues
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Inventories.Products AS Products,
	|	Inventories.Characteristic AS Characteristic,
	|	Inventories.Warehouse AS Warehouse,
	|	Inventories.Purpose AS Purpose,
	|	Inventories.InStockBalance AS InStockBalance,
	|	Inventories.LockedInStockBalance AS LockedInStockBalance,
	|	Inventories.OrderedBalance AS OrderedBalance,
	|	Inventories.Received_1Balance AS Received_1Balance,
	|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
	|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
	|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
	|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
	|	Inventories.ToSupplyBalance AS ToSupplyBalance,
	|	Inventories.NotProvideBalance AS NotProvideBalance
	|INTO InventoryAndDemandsBalance
	|FROM
	|	AccumulationRegister.InventoryAndDemands.Balance(
	|			,
	|			(Products, Characteristic, Purpose) IN
	|				(SELECT
	|					SelectionOfBalanceAnalogues.Products AS Products,
	|					SelectionOfBalanceAnalogues.Characteristic AS Characteristic,
	|					SelectionOfBalanceAnalogues.Purpose AS Purpose
	|				FROM
	|					SelectionOfBalanceAnalogues AS SelectionOfBalanceAnalogues)) AS Inventories
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose
	|;
	|
	|SELECT
	|	Calculation.Products AS Products,
	|	Calculation.Characteristic AS Characteristic,
	|	Calculation.Warehouse AS Warehouse,
	|	Calculation.Purpose AS Purpose,
	|	Calculation.Purpose <> VALUE(Catalog.Assignments.EmptyRef) AS WithAssignment,
	|	Calculation.QuantityForShipAction AS AvailableForInventoryAllocation
	|INTO StocksAreTemporary
	|FROM
	|	CalculationOfBalancesForSettingActions AS Calculation
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Warehouse AS Warehouse,
	|	Table.Purpose AS Purpose,
	|	ISNULL(InventoryTable.Count, Table.AvailableForInventoryAllocation) AS CountBalance
	|INTO AllBalance
	|FROM
	|	StocksAreTemporary AS Table
	|		LEFT JOIN InventoryTable AS InventoryTable
	|		ON Table.Products = InventoryTable.Products
	|			AND Table.Characteristic = InventoryTable.Characteristic
	|			AND Table.Warehouse = InventoryTable.Warehouse
	|			AND Table.Purpose = InventoryTable.Purpose
	|		LEFT JOIN TableOfReserves AS TableOfReserves
	|		ON Table.Products = TableOfReserves.Products
	|			AND Table.Characteristic = TableOfReserves.Characteristic
	|			AND Table.Warehouse = TableOfReserves.Warehouse
	|			AND Table.Purpose = TableOfReserves.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Warehouse,
	|	Table.Purpose,
	|	0
	|FROM
	|	SelectionOfBalanceAnalogues AS Table
	|WHERE
	|	NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					StocksAreTemporary AS StocksAreTemporary
	|				WHERE
	|					StocksAreTemporary.Products = Table.Products
	|					AND StocksAreTemporary.Characteristic = Table.Characteristic
	|					AND StocksAreTemporary.Warehouse = Table.Warehouse
	|					AND StocksAreTemporary.Purpose = Table.Purpose)
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Warehouse AS Warehouse,
	|	Table.Purpose AS Purpose,
	|	Table.Purpose <> VALUE(Catalog.Assignments.EmptyRef) AS WithAssignment,
	|	Table.CountBalance - ISNULL(SelectedAnalogues.Count, 0) AS AvailableForInventoryAllocation
	|FROM
	|	AllBalance AS Table
	|		LEFT JOIN SelectedAnalogues AS SelectedAnalogues
	|		ON Table.Products = SelectedAnalogues.Products
	|			AND Table.Characteristic = SelectedAnalogues.Characteristic
	|			AND Table.Warehouse = SelectedAnalogues.Warehouse
	|			AND Table.Purpose = SelectedAnalogues.Purpose
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				SelectionOfBalanceAnalogues AS SelectionOfBalanceAnalogues
	|			WHERE
	|				SelectionOfBalanceAnalogues.Products = Table.Products
	|				AND SelectionOfBalanceAnalogues.Characteristic = Table.Characteristic
	|				AND SelectionOfBalanceAnalogues.Warehouse = Table.Warehouse
	|				AND SelectionOfBalanceAnalogues.Purpose = Table.Purpose)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.Purpose <> VALUE(Catalog.Assignments.EmptyRef) AS WithAssignment,
	|	SUM(Table.CountBalance) AS AvailableForInventoryAllocation
	|FROM
	|	AllBalance AS Table
	|WHERE
	|	NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					SelectionOfBalanceAnalogues AS SelectionOfBalanceAnalogues
	|				WHERE
	|					SelectionOfBalanceAnalogues.Products = Table.Products
	|					AND SelectionOfBalanceAnalogues.Characteristic = Table.Characteristic
	|					AND SelectionOfBalanceAnalogues.Warehouse = Table.Warehouse
	|					AND SelectionOfBalanceAnalogues.Purpose = Table.Purpose)
	|
	|GROUP BY
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(Query.Text, TablesNames);
	
	TableOfAnalogues = New ValueTable;
	TableOfAnalogues.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfAnalogues.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfAnalogues.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	TableOfAnalogues.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	EmptyAssignment = Catalogs.Assignments.EmptyRef();
	
	For Each TableRow In Substitutes Do
	
		If TableRow.ThisIsASubstitute Then
			NewLineWithAssignment = TableOfAnalogues.Add();
			FillPropertyValues(NewLineWithAssignment, TableRow);
			NewLineWithAssignment.Purpose = Purpose;
			NewLineWithoutAssignment = TableOfAnalogues.Add();
			FillPropertyValues(NewLineWithoutAssignment, TableRow);
			NewLineWithoutAssignment.Purpose = EmptyAssignment;
		EndIf;
	
	EndDo;
	
	FilterStructure1 = New Structure("ThisIsASubstitute, SelectionOverBalance", True, False);
	ColumnsNames = "Products, Characteristic, Warehouse, Purpose, Count";
	TableSelectedAnalogues = SelectionPortions.Unload(FilterStructure1, ColumnsNames);
	TableSelectedAnalogues.GroupBy("Products, Characteristic, Warehouse, Purpose", "Count");
	
	Query.SetParameter("Inventories", Inventories.Unload());
	Query.SetParameter("TableOfAnalogues", TableOfAnalogues);
	Query.SetParameter("SelectedAnalogues", TableSelectedAnalogues);
	
	ResultsArray = Query.ExecuteBatch();
	
	NumberOfPackages_ = ResultsArray.UBound();
	RemnantsOfAnalogues.Load(ResultsArray[NumberOfPackages_ - 1].Unload());
	BalancesOfAnaloguesInOtherWarehouses.Load(ResultsArray[NumberOfPackages_].Unload());
		
	FillInBalanceInWarehouse(ThisObject, WithAssignment, Purpose);

EndProcedure

&AtClient
Function ItIsPossibleToSelectAnalogue()

	Result = True;
	curData = Items.Substitutes.CurrentData;
	
	If curData <> Undefined And Not ValueIsFilled(curData.Warehouse) 
		And SelectionModeWarehouse = ManuallySpecifiedWarehouseMode() And Not ValueIsFilled(AnalogSelectionWarehouse) Then
	
		Result = False;
		MessageText = NStr("vi = 'Để lựa chọn hàng tương tự, cần phải điền kho.';
							|ru = 'Для подбора аналогов должен быть заполнен склад.';
							|en = 'To pick substitutes, fill in the warehouse.'; fa = 'To pick substitutes, fill in the warehouse.';
							|it = 'To pick substitutes, fill in the warehouse.';
							|pl = 'To pick substitutes, fill in the warehouse.';
							|tr = 'İkame seçimi için ambar doldurulmalıdır.'");
		CommonClient.MessageToUser(MessageText,, "AnalogSelectionWarehouse");
	
	EndIf;
	
	Return Result;

EndFunction

&AtClient
Procedure UpdateDataOnForm()

	FillOutFormDataATServer();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction(False);
		OperationText = NStr("vi = 'Đang nhận dữ liệu...';
							|ru = 'Выполняется получение данных...';
							|en = 'Receiving data…'; fa = 'Receiving data…';
							|it = 'Ottenimento dei dati in corso...';
							|pl = 'Trwa pobieranie danych...';
							|tr = 'Veri alınıyor ...'");
		SetUpWaitingInForm(ThisObject, True, OperationText);
		
	Else
		
		PageName = ?(UsedMaterials.Count() = 1, "Substitutes", "UsedMaterials");
		SetUpWaitingInForm(ThisObject, False,, PageName);
		
	EndIf;	

EndProcedure

&AtClientAtServerNoContext
Procedure SetUpWaitingInForm(Form, ShowTimeConsumingOperation, PresentationOperation = "", PageName = "")
	
	Items = Form.Items;
	DetailsMode = Form.GeneralParameters.DetailsMode;
	
	If PageName = "Substitutes" Then
		FormPage = Items.AnalogsPage;
	Else
		FormPage = Items.PageMaterials;
	EndIf;
	
	Items.Pages.CurrentPage = ?(ShowTimeConsumingOperation,
		Items.TimeConsumingOperationPage, FormPage);
		
	Items.FormPerformAReplacement_3.Visible = Not ShowTimeConsumingOperation And Not DetailsMode;
	Items.FormOpenReplacementHistory.Visible = Not ShowTimeConsumingOperation And Not DetailsMode;
	Items.FormToCancelTheSelection.Visible = Not ShowTimeConsumingOperation And Not DetailsMode;
	Form.CommandBarLocation = ?(ShowTimeConsumingOperation,
		FormCommandBarLabelLocation.None, FormCommandBarLabelLocation.Auto);
	
	Items.TimeConsumingOperationPresentation.Title = PresentationOperation;
	
EndProcedure

&AtServer
Procedure FillOutFormDataATServer(ReFilling_ = False)
		
	CancelLongRunningOperation();
	
	TableOfGoods = GetFromTempStorage(GoodsParameters.Goods);
	If TableOfGoods.Count() = 0 Then
		Return;
	EndIf;
	
	ArrayOfLineNumbers = New Array;
	SelectedRows = Items.UsedMaterials.SelectedRows;
	For Each RowID In SelectedRows Do
		ArrayOfLineNumbers.Add(UsedMaterials.FindByID(RowID).LineNumber);	
	EndDo;
	
	ConsiderInventory = IsTempStorageURL(GoodsParameters.InventoryAllocation);
	InventoryTable = ?(ConsiderInventory, GetFromTempStorage(GoodsParameters.InventoryAllocation), Undefined); //ValueTable - 
	GoodsTogetherWithParameters = GoodsParameters.GoodsTogetherWithParameters;
	
	ParametersTable = ?(GoodsTogetherWithParameters, TableOfGoods, GetFromTempStorage(SubstitutesParameters.ParametersTable));
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("GeneralParameters", GeneralParameters);
	ProcedureParameters.Insert("GoodsParameters", GoodsParameters);
	ProcedureParameters.Insert("SubstitutesParameters", SubstitutesParameters);
	ProcedureParameters.Insert("ReFilling_", ReFilling_);
	ProcedureParameters.Insert("PermissionValidityDate", PermissionValidityDate);
	ProcedureParameters.Insert("UsedMaterials", UsedMaterials.Unload());
	ProcedureParameters.Insert("Substitutes", Substitutes.Unload());
	ProcedureParameters.Insert("RemnantsOfAnalogues", RemnantsOfAnalogues.Unload());
	ProcedureParameters.Insert("TableOfGoods", TableOfGoods);
	ProcedureParameters.Insert("ConsiderInventory", ConsiderInventory);
	ProcedureParameters.Insert("InventoryTable", InventoryTable);
	ProcedureParameters.Insert("ParametersTable", ParametersTable);
	ProcedureParameters.Insert("ArrayOfLineNumbers", ArrayOfLineNumbers);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lựa chọn hàng tương tự: điền dữ liệu';
														|ru = 'Подбор аналогов: заполнение данных';
														|en = 'Pick substitutes: fill in data'; fa = 'Pick substitutes: fill in data';
														|it = 'Pick substitutes: fill in data';
														|pl = 'Pick substitutes: fill in data';
														|tr = 'İkame seçimi: veri doldurma'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.EngineeringChangeOrder.SelectionOfAnaloguesFillInData",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = "FillInDataOnDeferredBasisCompletion";
		StartAwaitingLongAction = True;
		
	Else
		
		FillInDataOnDeferredBasis(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDataOnDeferredBasisCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		FillInDataOnDeferredBasis(Result);
		PageName = ?(UsedMaterials.Count() = 1, "Substitutes", "UsedMaterials");
		SetUpWaitingInForm(ThisObject, False,, PageName);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDataOnDeferredBasis(Result)
	
	If Result.Status = "Completed2" Then
		
		FillingData = GetFromTempStorage(Result.ResultAddress);
		
		UsedMaterials.Load(FillingData.UsedMaterials);
		Substitutes.Load(FillingData.Substitutes);
		Inventories.Load(FillingData.Inventories);
		RemnantsOfAnalogues.Load(FillingData.RemnantsOfAnalogues);
		BalancesOfAnaloguesInOtherWarehouses.Load(FillingData.BalancesOfAnaloguesInOtherWarehouses);
		FillPropertyValues(ThisObject, FillingData.FormAttributes);
		
		FillInServiceDetailsOfTableParts(FillingData.ReFilling_);
		
		If FillingData.ReFilling_ Then
			
			ArrayOfLineNumbers = FillingData.ArrayOfLineNumbers;
			
			SetCurrentRow = True;
			Items.UsedMaterials.SelectedRows.Clear();
			For Each LineNumber In ArrayOfLineNumbers Do
				
				RowID = UsedMaterials.FindRows(New Structure("LineNumber", LineNumber))[0].GetID();
				
				If SetCurrentRow Then
					Items.UsedMaterials.CurrentRow = RowID;
					SetCurrentRow = False;
				Else	
					Items.UsedMaterials.SelectedRows.Add(RowID);
				EndIf;	
				
			EndDo;
			
			If Items.Pages.CurrentPage = Items.AnalogsPage Then
				FillInBalanceInWarehouse(ThisObject, SeparatePosition, Purpose);
				SetPermissionsPresentation(UsedMaterials[0].Products, UsedMaterials[0].Characteristic);
				FillInTotals(ThisObject);
				InstallInscriptionLackOfAnalogues(ThisObject);
			EndIf;
			
		Else
			
			If Items.UsedMaterials.CurrentRow = Undefined Then
				Items.UsedMaterials.CurrentRow = 0;
			EndIf;
			
			ConsiderInventory = IsTempStorageURL(GoodsParameters.InventoryAllocation);
			
			PageName = ?(UsedMaterials.Count() = 1, "Substitutes", "UsedMaterials");
			SetInitialPageLayout(PageName, GeneralParameters.ShowBalance, ConsiderInventory);
			
			If GeneralParameters.DetailsMode Then
			
				SetFormSettingsInDecryptionMode();
			
			EndIf;
		
		EndIf;
		
	Else
		
		If Result.Status = "Error" Then
			
			Raise Result.BriefErrorDescription;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelLongRunningOperation()
	
	If Not TimeConsumingOperation = Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAwaitingLongAction(OutputIdleWindow = True)
	
	CallbackOnCompletion = New CallbackDescription(TimeConsumingOperationIdleHandler, ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	IdleParameters.OutputIdleWindow = OutputIdleWindow;
	
	TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			CallbackOnCompletion,
			IdleParameters);
	
	StartAwaitingLongAction = False;
	
EndProcedure

&AtServer
Procedure SetFormSettingsInDecryptionMode()

	AutoTitle = False;
	Title     = NStr("vi = 'Diễn giải mặt hàng tương tự';
					|ru = 'Расшифровка аналогов';
					|en = 'Substitute drill-down'; fa = 'Substitute drill-down';
					|it = 'Расшифровка аналогов';
					|pl = 'Substitute drill-down';
					|tr = 'İkamelerin detaylandırılması'");
	
	ItemsNames = New Array;
	ItemsNames.Add("AnalogsCapRequiredReplaced");
	ItemsNames.Add("AnalogsBasement");
	ItemsNames.Add("SubstitutesCount");
	ItemsNames.Add("SubstitutesIsBalance");
	ItemsNames.Add("TheLabelLackOfAnalogues");
	ItemsNames.Add("ReplacementSourceOnTheAnalogsPage");
	ItemsNames.Add("PermissionValidityDate");
	ItemsNames.Add("FormPerformAReplacement_3");
	ItemsNames.Add("FormOpenReplacementHistory");
	ItemsNames.Add("ButtonCancelSelection");
	ItemsNames.Add("SelectionModeWarehouse");
	ItemsNames.Add("AnalogSelectionWarehouse");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemsNames, "Visible", False);
	
	ItemsNames = New Array;
	ItemsNames.Add("FormClose");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemsNames, "Visible", True);

EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_PermissionValidityDate" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
