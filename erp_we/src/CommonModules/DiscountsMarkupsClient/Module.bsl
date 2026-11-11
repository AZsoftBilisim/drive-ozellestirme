
#Region Public

#Region ExportFunctionsForInteractiveWorkWithDiscounts

// Opens the form for editing the discount terms and conditions
//
// Parameters:
//  ConditionType                  - EnumRef.DiscountMarkupTerms - type of condition to create.
//  DataToFillInForTheParent - CatalogRef.DiscountMarkupTerms - the parent of the new
//                                condition will be set to the parent of the condition passed in this parameter.
//  UseTermsOfServiceCatalogForm - Boolean - 
//                                If True, 
//                                the form of the Catalog item will be opened. Discount conditions, if False, the Discount Catalog item form will be opened.
//
Procedure CreateConditionForGrantingDiscountMarkUp(ConditionType,
	                                                DataToFillInForTheParent = Undefined,
	                                                UseTermsOfServiceCatalogForm = True) Export
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", New Structure("DiscountMarkupCondition", ConditionType));
	ParametersStructure1.Insert("DataToFillInForTheParent",
	                            ?(DataToFillInForTheParent = Undefined,
	                              PredefinedValue("Catalog.DiscountMarkupTerms.EmptyRef"),
	                              DataToFillInForTheParent));
	
	FormName = ?(UseTermsOfServiceCatalogForm,
	            "Catalog.DiscountMarkupTerms.Form.ItemForm",
	            "Catalog.DiscountMarkupTerms.Form.InputFormOfANewOne");
	
	OpenForm(FormName, ParametersStructure1);

EndProcedure

Procedure CreateDiscountMarkUp(MethodsOfProviding, DiscountApplicationMethod,
	                           DataToFillInForTheParent = Undefined) Export
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", New Structure(
		"MethodsOfProviding, DiscountApplicationMethod, DataToFillInForTheParent",
		MethodsOfProviding, DiscountApplicationMethod, DataToFillInForTheParent));
	
	OpenForm("Catalog.DiscountsMarkups.Form.ItemForm", ParametersStructure1);

EndProcedure

// Opens the form for a new discount condition (mark-up).
//
// Parameters:
//  Form         - ClientApplicationForm - object form.
//  Command       - FormCommand - form command.
//  CurrentRow - FormDataStructure - Current line.
//
Procedure ProcessCommandToAddConditionsForGrantingDiscountsMarkups(Form, Command, CurrentRow) Export
	
	For Each TSRow In Form.TermsCommands Do
		
		If TSRow.CommandName = Command.Name Then
			
			DiscountsMarkupsClient.CreateConditionForGrantingDiscountMarkUp(
			                 TSRow.Value,
			                 CurrentRow, False);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Opens the new discount (mark-up) form)
//
// Parameters:
//  Form         - ClientApplicationForm - object form.
//  Command       - FormCommand - form command.
//  CurrentRow - FormDataStructure - Current line.
//
Procedure ProcessCommandToAddDiscountMarkUp(Form, Command, CurrentRow) Export
	
	For Each TSRow In Form.TermsCommands Do
		
		If TSRow.CommandName = Command.Name Then
			
			DiscountApplicationMethod = PredefinedValue("Enum.DiscountMarkupApplicationMethods.ApplyDuringCalculationOfDiscountsMarkups");
			If StrFind(Command.Name, "BonusPoints") > 0 Then
				DiscountApplicationMethod = PredefinedValue("Enum.DiscountMarkupApplicationMethods.GrantBonusPoints");
			EndIf;
			
			DiscountsMarkupsClient.CreateDiscountMarkUp(
				TSRow.Value,
				DiscountApplicationMethod,
				CurrentRow);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Opens the selection settings form.
//
// Parameters:
//  Form     - ClientApplicationForm - object form.
//  Name       - String - Name.
//  Addresses    - Structure - structure with properties:
//   * DataCompositionSchema - DataCompositionSchema - scheme of the layout.
//   * DataCompositionSettings - DataCompositionSettings - customization.
//
Procedure ConfigureFilter(Form, Name, Addresses) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	FormParameters.Insert("NotEditDataCompositionSchema", True);
	FormParameters.Insert("DoNotLoadADataLayoutDiagramFromAFile", True);
	FormParameters.Insert("DoNotConfigureConditionalFormatting", True);
	FormParameters.Insert("DoNotConfigureTheSelection", True);
	FormParameters.Insert("DonTAdjustTheOrder", True);
	FormParameters.Insert("DoNotConfigureSettings", True);
	FormParameters.Insert("UUID", Form.UUID);
	FormParameters.Insert("AddressOfDataCompositionSchema", Addresses.DataCompositionSchema);
	FormParameters.Insert("AddressOfDataCompositionSettings", Addresses.DataCompositionSettings);
	FormParameters.Insert("Title", NStr("vi = 'Chỉnh sửa lựa chọn';
										|ru = 'Редактирование отбора';
										|en = 'Edit filter'; fa = 'Edit filter';
										|it = 'Modifica della selezione';
										|pl = 'Edycja wyboru';
										|tr = 'Filtre düzenleme'"));
	FormParameters.Insert("ReadOnly", Form.Items.ItemFilterOption.ReadOnly);
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		FormParameters,,,,,
			New CallbackDescription(
				"EditDataCompositionSchemaCompletion",
				Form,
				New Structure("Name", Name)),
				FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

#EndRegion

#Region GeneralProceduresFunctionsOfDiscountConditionsForms

// Update auto-naming of discount terms.
//
// Parameters:
//  Form - ClientApplicationForm - The Form Of the object. Contains including:
//  	* Object - CatalogObject - Catalog
//  Refresh - Boolean - Indicates whether auto-naming needs to be updated.
//
Procedure UpdateAutoNamingDiscountTermsAndConditions(Form, Refresh = True) Export
	
	Description = DiscountsMarkupsClientServer.AutoNameDiscountConditions(Form);
	If Not ValueIsFilled(Form.Object.Description) Or (Refresh And Form.AutoNameIsUsed And Not Form.NameIsChangedByUser) Then
		Form.Object.Description = Description;
		Form.AutoNameIsUsed = True;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Expands the tree rows either unconditionally or only those specified in the list.
//
// Parameters:
//  TreeRow          - FormDataTree    - a string whose subordinate elements will be expanded
//  FormItem          - FormTable         - the form element where the tree is located.
//  ExpandedTreeNodes - ValueList       - a list that stores the values of discounts (mark-UPS), 
//                                                 the corresponding nodes of which will be expanded.
//
Procedure ExpandDiscountTreeRecursively(TreeRow, FormItem, ExpandedTreeNodes = Undefined) Export
	
	ItemsCollection = TreeRow.GetItems();
	For Each Item In ItemsCollection Do
		
		If ExpandedTreeNodes <> Undefined Then
			If ExpandedTreeNodes.FindByValue(Item.Ref) <> Undefined Then
				FormItem.Expand(Item.GetID());
			EndIf;
		Else
			FormItem.Expand(Item.GetID());
		EndIf;
		
		ExpandDiscountTreeRecursively(Item, FormItem, ExpandedTreeNodes);
		
	EndDo;
	
EndProcedure

// Defines the ID of a tree row based on the value of one of the columns
//
// Parameters:
//  WhereToFind          - ValueTree - form details containing a tree of values.
//  Value           - Arbitrary - the value that is being searched for.
//  Column            - String - name of the tree column to search for the value in.
//  SearchSubordinateItems - Boolean - indicates whether to search in subordinate nodes.
//
// Returns:
//  Number - row ID, -1 if the row is not found.
//
Function TreeRowID(WhereToFind, Value, Column, SearchSubordinateItems) Export
	
	TreeItems = WhereToFind.GetItems();
	
	For Each TreeItem In TreeItems Do
		If TreeItem[Column] = Value Then
			Return TreeItem.GetID();
		ElsIf  SearchSubordinateItems Then
			FoundRowID1 = TreeRowID(TreeItem, Value, Column, SearchSubordinateItems);
			If FoundRowID1 >=0 Then
				Return FoundRowID1;
			EndIf;
		EndIf;
	EndDo;
	
	Return -1;
	
EndFunction

// Performs positioning on a tree row by the value in the specified column
//
// Parameters:
//  DiscountMarkup - CatalogRef.DiscountsMarkups - the value to use for positioning.
//  FormTree   - ValueTree - form details containing a tree of values.
//  FormItem  - FormTable - the form element where the tree is located.
//  ColumnName    - String - the name of the column tree, which is searched for values which need to be positioned.
//
Procedure PositionOnValueInTree(DiscountMarkup, FormTree, FormItem, ColumnName) Export
	
	If Not DiscountMarkup.IsEmpty() Then
		IDFound = TreeRowID(FormTree, DiscountMarkup, ColumnName, True);
		If IDFound <> -1 Then
			FormItem.CurrentRow = IDFound;
		EndIf;
	EndIf;

	
EndProcedure

// If the node is expanded, the discount (mark-up) of this node is saved in the list. if it is collapsed, it is deleted.
//
// Parameters:
//  String                  - FormDataTreeItem - a string that expands or collapses
//  FormItem            - FormTable - the form element where the tree is located
//  ExpandedNodesList  - ValueList - a list in which to store expanded nodes.
//  Expansion          - Boolean - True if the node is expanded. False if collapses.
//
Procedure SaveWhetherTreeNodeIsExpandedInList(String, FormItem, ExpandedNodesList, Expansion) Export

	RowData = FormItem.RowData(String);
	If RowData <> Undefined Then
		
		FoundListItem = ExpandedNodesList.FindByValue(RowData.Ref);
		
		If Expansion Then
			If FoundListItem = Undefined Then
				ExpandedNodesList.Add(RowData.Ref);
			EndIf;
		Else
			If FoundListItem <> Undefined Then
				ExpandedNodesList.Delete(FoundListItem);
			EndIf;
		EndIf;
		
	EndIf;

EndProcedure 

// Opens the form for setting the discount (mark-up) status by source
//
// Parameters:
//  Form     - ClientApplicationForm - form from which you open the form set the status.
//  Status    - EnumRef.DiscountValidityStatuses - the status to be set.
//  Source  - CatalogRef.Warehouses, CatalogRef.LoyaltyCardKinds, CatalogRef.TermsOfSale -
//              the source of the discount.
//
Procedure OpenStatusSettingForm(Form, Status, Source) Export
	
	If Not ValueIsFilled(Source) Then
		QueryText = NStr("vi = 'Để thay đổi trạng thái hiệu lực của chiết khấu (phụ thu), cần ghi lại đối tượng. Ghi lại?';
						|ru = 'Для изменения статуса действия скидки (наценки) необходимо записать объект. Записать?';
						|en = 'To change the discount (markup) status, save the object. Do you want to save it?'; fa = 'To change the discount (markup) status, save the object. Do you want to save it?';
						|it = 'Per modificare lo stato dell''azione dello sconto (markup) è necessario salvare l''oggetto. Salvare?';
						|pl = 'Aby zmienić status działania rabatu (marży), musisz zarejestrować obiekt. Zapisać?';
						|tr = 'İndirim/zam eylem işlem değiştirmek için nesnenin kaydedilmesi gerekir. Kaydet?'");
		Response = Undefined;
		
		ShowQueryBox(New CallbackDescription("OpenStatusSettingFormCompletion", ThisObject, New Structure("Status, Form", Status, Form)), QueryText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	OpenFragmentStatusSettingForm(Source, Status, Form);
	
EndProcedure

// * Service procedure
Procedure OpenStatusSettingFormCompletion(QuestionResult, AdditionalParameters) Export
	
	Status = AdditionalParameters.Status;
	Form  = AdditionalParameters.Form;
	
	Response = QuestionResult;
	If Response = DialogReturnCode.Yes Then
		Form.Write();
	Else
		Return;
	EndIf;
	
	Source = Form.Parameters.Key;
	If ValueIsFilled(Source)Then
		OpenFragmentStatusSettingForm(Source, Status, Form);
	Else
		ErrorText = NStr("vi = 'Không thể thay đổi trạng thái giảm giá (phụ thu).';
						|ru = 'Не удалось выполнить изменение статусов скидок (наценок).';
						|en = 'Cannot change the discount (markup) statuses.'; fa = 'Cannot change the discount (markup) statuses.';
						|it = 'Impossibile modificare gli stati degli sconti (markup).';
						|pl = 'Nie udało się zmienić statusu rabatów (marż).';
						|tr = 'İndirimlerin/zamların durumları değiştirilemedi.'");
		CommonClientServer.MessageToUser(ErrorText);
	EndIf;
	
EndProcedure

// * Service procedure
Procedure OpenFragmentStatusSettingForm(Val Source, Val Status, Val Form)
	
	Var RowID, ArrayDiscountsMargins, OpeningParameters, TSRow;
	
	ArrayDiscountsMargins = New Array;
	ArrayOfProductItemItems = New Array;
	
	TypeOfGNPSource = TypeOf(Source);
	
	If TypeOfGNPSource = Type("CatalogRef.TermsOfSale")
		Or TypeOfGNPSource = Type("CatalogRef.LoyaltyCardKinds")
		Or TypeOfGNPSource = Type("CatalogRef.Warehouses") Then
		
		For Each RowID In Form.Items.DiscountsMarkups.SelectedRows Do
			TSRow = Form.DiscountsMarkups.FindByID(RowID);
			If TSRow.IsFolder Then
				Continue;
			EndIf;
			ArrayDiscountsMargins.Add(TSRow.Ref);
		EndDo;
		
		If ArrayDiscountsMargins.Count() = 0 Then
			ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn chiết khấu (phụ thu) để thay đổi trạng thái.';
											|ru = 'Не выбраны скидки (наценки) для изменения статуса.';
											|en = 'Discounts (markups) for changing status are not selected.'; fa = 'Discounts (markups) for changing status are not selected.';
											|it = 'Nessuno sconto (markup) selezionato per la modifica dello stato.';
											|pl = 'Brak rabatu (marży) dla zmiany statusu.';
											|tr = 'Durum değişikliği için hiçbir indirim/zam seçilmedi.'"));
			Return;
		EndIf;
		
	EndIf;
	
	If TypeOfGNPSource = Type("CatalogRef.DiscountMarkupTerms")
		Or TypeOfGNPSource = Type("CatalogRef.DiscountsMarkups") Then
		
		For Each RowID In Form.Items.Goods.SelectedRows Do
			TSRow = Form.Items.Goods.RowData(RowID);
			NewRow = New Structure;
			NewRow.Insert("Products", TSRow.Products);
			NewRow.Insert("Characteristic", TSRow.Characteristic);
			ArrayOfProductItemItems.Add(NewRow);
		EndDo;
		
		If ArrayOfProductItemItems.Count() = 0 Then
			ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn mục mặt hàng để thay đổi trạng thái.';
											|ru = 'Не выбраны позиции номенклатуры для изменения статуса.';
											|en = 'Product items for changing status are not selected.'; fa = 'Product items for changing status are not selected.';
											|it = 'Nessun articolo selezionato per la modifica dello stato.';
											|pl = 'Nie wybrano pozycji nomenklatury do zmiany statusu.';
											|tr = 'Durum değişikliği için seçilmeyen öğe konumları.'"));
			Return;
		EndIf;
		
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("StartDate",          Form.SliceDate);
	OpeningParameters.Insert("DiscountMarkup",       ArrayDiscountsMargins);
	OpeningParameters.Insert("ItemItemPosition", ArrayOfProductItemItems);
	OpeningParameters.Insert("Source", Source);
	OpeningParameters.Insert("Status",   Status);
	
	OpenForm(
		"Catalog.DiscountsMarkups.Form.SettingOfValidityStatus",
		OpeningParameters,
		Form);
	
EndProcedure

// Opens the history form for changing the discount status (mark-up) by source
//
// Parameters:
//  Form     - ClientApplicationForm - The Form from which the story opens. Contains including:
//  	* Object - CatalogObject - Catalog
//  Source  - CatalogRef.Warehouses, CatalogRef.LoyaltyCardKinds, CatalogRef.TermsOfSale -
//              the source of the discount action, if Undefined, the source is considered to be the object of the form from which
//              the history is opened.
//
Procedure OpenStatusChangeHistoryForm(Form, Source = Undefined) Export
	
	If Source = Undefined Then
		Source = Form.Object.Ref;
	EndIf;
	
	If Not ValueIsFilled(Source) Then
		WarningText = NStr("vi = 'Đối với đối tượng này vẫn chưa có lịch sử thay đổi trạng thái
		                            |hiệu lực của chiết khấu (phụ thu), bởi vì vẫn chưa ghi lại đối tượng.';
		                            |ru = 'Для данного объекта еще нет истории изменения статусов
		                            |действия скидок (наценок) так как объект еще не записан.';
		                            |en = 'No change history of discount (markup) validity status is available
		                            |for this object as the object is not saved yet.'; fa = 'No change history of discount (markup) validity status is available
		                            |for this object as the object is not saved yet.';
		                            |it = 'Per questo oggetto, non esiste ancora una cronologia di modifica dello stato
		                            | degli sconti (markup) poiché l''oggetto non è stato ancora salvato.';
		                            |pl = 'Dla tego obiektu nie ma historii zmian statusu
		                            |działania rabatów (marż), ponieważ obiekt nie został jeszcze zarejestrowany.';
		                            |tr = 'Bu nesne için indirim/zam durumlarının değişiklik geçmişi yoktur,
		                            |çünkü nesne henüz kaydedilmemiştir.'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	
	DiscountMarkup = Undefined;
	ItemItemPosition = Undefined;
	
	If TMCommonUseClientServer.HasObjectAttribute(Form.Items, "DiscountsMarkups") Then
		CurrentData = Form.Items.DiscountsMarkups.CurrentData;
		If CurrentData = Undefined Or CurrentData.IsFolder Then
			Return;
		EndIf;
		DiscountMarkup = CurrentData.Ref;
	EndIf;
	
	If (Source = Undefined Or TypeOf(Source) = Type("CatalogRef.DiscountsMarkups"))
		And TMCommonUseClientServer.HasObjectAttribute(Form.Items, "Goods") Then
		
		CurrentData = Form.Items.Goods.CurrentData;
		If CurrentData = Undefined Then
			Return;
		EndIf;
		ItemItemPosition = New Structure(
			"Products, Characteristic",
			CurrentData.Products,
			CurrentData.Characteristic);
		
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Source",            Source);
	OpeningParameters.Insert("DiscountMarkup",       DiscountMarkup);
	OpeningParameters.Insert("ItemItemPosition", ItemItemPosition);
	OpenForm(
		"Catalog.DiscountsMarkups.Form.DiscountMarkupValidityHistory",
		OpeningParameters,
		Form);
		
EndProcedure

#EndRegion
