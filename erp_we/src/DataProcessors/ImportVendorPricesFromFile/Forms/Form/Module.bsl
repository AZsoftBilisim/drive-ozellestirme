#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details
&AtClient
Var OldProducts; // It is used in the mechanisms of event handlers of the tabular part of the Goods
&AtClient
Var OldPartnerProducts; // It is used in the mechanisms of event handlers of the tabular part of the Goods
&AtClient
Var OldCharacteristic; // It is used in the mechanisms of event handlers of the tabular part of the Goods
&AtClient
Var Changed_Price; // It is used in the mechanisms of event handlers of the tabular part of the Goods

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FormCode = "ImportVendorPricesFromFile";
	
	Object.Date = EndOfDay(CurrentSessionDate());
	
	UsePartnersProducts    = GetFunctionalOption("UsePartnersProducts");
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemPackages       = GetFunctionalOption("UseItemPackages");
	
	FillInDataType = TypeOf(Parameters.Basis);
	Object.Partner = Parameters.Partner;
	
	SetAvailabilityOfChoiceOfTypesOfPrices();
	
	If Parameters.BlockTheChangeOfFilterBySupplier Then
		Items.Partner.ReadOnly = Parameters.BlockTheChangeOfFilterBySupplier;
	EndIf;
	
	SettingPricesServer.InitializeSelectedPrices(ThisObject);
	
	For Each TSRow In SelectedPrices Do
		TSRow.Selected_5 = Parameters.TypesOfPrices.Find(TSRow.Ref) <> Undefined;
	EndDo;
	
	FillServiceColumnsOfPriceTypes();
	
	SetConditionalAppearanceForOrder();
	
	SettingPricesServer.BuildPriceTree(ThisObject);
	InitializeTableDocument();
	
	If ValueIsFilled(Object.Partner) Then
		MapCatalogs = True;
	EndIf;

	If Not UsePartnersProducts Then
		Items.PriceTreeProducts.DropListButton = True;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.ImportVendorPricesFromFile.Form.SelectionOfVendorPriceTypesForm" Then
	
		UpdatePriceViewColumns(ValueSelected);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForceCloseTheForm Or Exit Then
		Return;
	EndIf;
	
	If Not Done And Modified Then
		
		Cancel = True;
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatma'"));
		
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
			NStr("vi = 'Trợ giúp sẽ kết thúc công việc,
			           |tất cả dữ liệu đã nhập sẽ bị mất. Đóng trợ giúp?';
			           |ru = 'Работа помощника будет завершена,
			           |все введенные данные будут потеряны. Закрыть помощник?';
			           |en = 'Wizard will be closed and
			           |all the entered information will be lost. Close the wizard?'; fa = 'Wizard will be closed and
			           |all the entered information will be lost. Close the wizard?';
			           |it = 'Il lavoro dell''assistente sarà completato, 
			           |tutti i dati immessi andranno persi. Chiudere assistente?';
			           |pl = 'Praca asystenta będzie zakończona,
			           |wszystkie wprowadzone dane zostaną utracone. Zamknąć asystent?';
			           |tr = 'Sihirbazın çalışması sonlandırılacak,
			           |tüm girilen verilen kaybolacaktır. Sihirbaz kapatılsın mı?'"),
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "Close" Then
		ForceCloseTheForm = True;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	DoNotCheckTheMatchedPartnerItem = Settings.Get("DoNotCheckTheMatchedPartnerItem");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	SettingPricesServer.InitializeSelectedPrices(ThisObject);
	
	ColumnNumber = 3;
	For Each TSRow In SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject) Do
		
		TSRow.NameSearch = Upper(StrReplace(TSRow.Description, " ", ""));
		TSRow.MXLColumnName = ColumnNumber;
		TSRow.Selected_5 = True;
		
		ColumnNumber = ColumnNumber + 1;
		
	EndDo;
	
	SettingPricesServer.BuildPriceTree(ThisObject);
	
	InitializeTableDocument();
	
	SetAvailabilityOfChoiceOfTypesOfPrices();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure PartnerClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Object.Partner = PredefinedValue("Catalog.Partners.EmptyRef");
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure SpreadsheetDocumentOnChange(Item)
	
	MapCatalogs = True;
	
EndProcedure

&AtClient
Procedure LoadOnlyTheMatchedItemOption(Command)
	SetToLoadOnlyMappedProducts(Not RegisterOnlyTheRecognizedItem);
EndProcedure
	
	
&AtClient
Procedure SetToLoadOnlyMappedProducts(NewValue)
	
	RegisterOnlyTheRecognizedItem = NewValue;
	Items.SwitchToRegisterOnlyRecognizedTheItem.Check = NewValue;
	
	SetSelectionByProduct_();
EndProcedure

&AtClient
Procedure ProductsDisplayOptionOnChange(Item)
	
	SetSelectionByProduct_();
	
EndProcedure

&AtClient
Procedure PriceTreeOnActivateRow(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	PartnersProductsClient.SetPackageSelectionParameters(
			Items.PriceTreePartnerProducts.ChoiceParameters, CurrentData);
	
	If CurrentData.ProductsQuantityForSelection = 0 Then
		Return;
	EndIf;
	
	ArrayOfPartnerProducts = New Array();
	
	If ValueIsFilled(CurrentData.SKU) Then
		
		FoundRows = PartnerProducts.FindRows(
			New Structure("ProductIDSearch", Upper(StrReplace(CurrentData.SKU, " ", ""))));
		
		For Each FoundRow In FoundRows Do
			ArrayOfPartnerProducts.Add(FoundRow);
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(CurrentData.NomenclatureName) Then
		
		FoundRows = PartnerProducts.FindRows(
			New Structure("Description", Upper(StrReplace(CurrentData.NomenclatureName, " ", ""))));
		
		For Each FoundRow In FoundRows Do
			If ArrayOfPartnerProducts.Find(FoundRow) = Undefined Then
				ArrayOfPartnerProducts.Add(FoundRow);
			EndIf;
		EndDo;
		
	EndIf;
	
	If UsePartnersProducts Then
		FormItem = Items.PriceTreePartnerProducts;
	Else
		FormItem = Items.PriceTreeProducts;
	EndIf;
	
	FormItem.ChoiceList.Clear();
	
	If ArrayOfPartnerProducts.Count() > 0 Then
		
		For Each CurItem In ArrayOfPartnerProducts Do
			FormItem.ChoiceList.Add(CurItem.Ref, CurItem.Description + " " + "(" + CurItem.SKU + ")");
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceTreeOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.PriceTree.CurrentData;
	OldPartnerProducts = CurrentData.PartnerProducts;
	OldProducts = CurrentData.Products;
	OldCharacteristic = CurrentData.Characteristic;
	Changed_Price = False;
	
EndProcedure

&AtClient
Procedure PriceTreeBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData.Products <> OldProducts Or Not ValueIsFilled(CurrentData.Products) Then
		
		For Each ProductItem In PriceTree Do
			If (ProductItem.Products = CurrentData.Products And ProductItem.Characteristic = CurrentData.Characteristic)
				Or (Not ValueIsFilled(ProductItem.Products)
				     And ProductItem.PartnerProducts = CurrentData.PartnerProducts) Then
				
				If CurrentData.GetID() <> ProductItem.GetID() And ValueIsFilled(ProductItem.Products) Then
					If Not CancelEdit Then
						Cancel = True;
						ClearMessages();
						CommonClient.MessageToUser(
							NStr("vi = 'Đã nhập mặt hàng này.';
								|ru = 'Такая номенклатура уже введена.';
								|en = 'These products already exist.'; fa = 'These products already exist.';
								|it = 'Questo articolo è già stato inserito.';
								|pl = 'Ten wykaz towarów jest już wprowadzony.';
								|tr = 'Böyle bir öğe zaten girildi.'"),,
							"PriceTree");
					Else
						CurrentData.Products = OldProducts;
						CurrentData.Characteristic = OldCharacteristic;
					EndIf;
					Return;
				EndIf;
			EndIf;
		EndDo;
		
		PriceTreeProductsOnChangeServer(Items.PriceTree.CurrentData.GetID());
		
	EndIf;
	
	If Not ValueIsFilled(CurrentData.Products)
		And Not ValueIsFilled(CurrentData.PartnerProducts) Then
		If Not CancelEdit Then
			Cancel = True;
			ClearMessages();
			CommonClient.MessageToUser(
				NStr("vi = 'Chưa chọn mặt hàng.';
					|ru = 'Номенклатура не выбрана.';
					|en = 'Items are not selected.'; fa = 'Items are not selected.';
					|it = 'Articolo non selezionato.';
					|pl = 'Nie wybrano wykazu towarów.';
					|tr = 'Öğe seçilmedi.'"),,
				"PriceTree");
		Else
			CurrentData.PartnerProducts = OldPartnerProducts;
			CurrentData.Products = OldProducts;
			CurrentData.Characteristic = OldCharacteristic;
		EndIf;
	EndIf;
	
	If CurrentData.Characteristic <> OldCharacteristic Then
		
		For Each ProductItem In PriceTree Do
			If (ProductItem.Products = CurrentData.Products And ProductItem.Characteristic = CurrentData.Characteristic)
				Or (Not ValueIsFilled(ProductItem.Products)
					And ValueIsFilled(ProductItem.PartnerProducts)
					And ProductItem.PartnerProducts = CurrentData.PartnerProducts) Then
				
				If CurrentData.GetID() <> ProductItem.GetID() Then
					If Not CancelEdit Then
						Cancel = True;
						ClearMessages();
						CommonClient.MessageToUser(
							NStr("vi = 'Đã nhập mặt hàng này.';
								|ru = 'Такая номенклатура уже введена.';
								|en = 'These products already exist.'; fa = 'These products already exist.';
								|it = 'Questo articolo è già stato inserito.';
								|pl = 'Ten wykaz towarów jest już wprowadzony.';
								|tr = 'Böyle bir öğe zaten girildi.'"),,
							"PriceTree");
					Else
						CurrentData.Products = OldProducts;
						CurrentData.Characteristic = OldCharacteristic;
					EndIf;
					Return;
				EndIf;
			EndIf;
		EndDo;
		
		PriceTreeCharacteristicOnChangeServer(Items.PriceTree.CurrentData.GetID());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceTreePartnerProductsClearing(Item, StandardProcessing)
	
	CurrentRow = Items.PriceTree.CurrentData;
	
	If Not ValueIsFilled(CurrentRow.PartnerProducts) Then
		
		StandardProcessing = False;
		Items.PriceTree.EndEditRow(True);
		
	EndIf;
	
	
EndProcedure

#EndRegion

#Region EventHandlersForPriceTreeTableElements

&AtClient
Procedure PriceTreeProductsOnChange(Item)

	CurrentRow = Items.PriceTree.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckMatchedPartnerProducts",
		BatchProcessingOfTablePartClientServer.GetValidationStructureOfMatchedSupplierProductInTSLine(
			New Structure(
				"Ref, Partner",
				PredefinedValue("Document.VendorPriceList.EmptyRef"),
				Object.Partner),
			DoNotCheckTheMatchedPartnerItem));
	
	AdditionalFillingParameters = New Structure("LineNumber", Items.PriceTree.CurrentRow);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters);

	CurrentRow.RowMapped = ValueIsFilled(CurrentRow.Products);
	
	MarkDuplicatesOfTablePart();
	
EndProcedure

&AtClient
Procedure PriceTreeCharacteristicOnChange(Item)
	
	CurrentRow = Items.PriceTree.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckMatchedPartnerProducts",
		BatchProcessingOfTablePartClientServer.GetValidationStructureOfMatchedSupplierProductInTSLine(
			New Structure(
				"Ref, Partner",
				PredefinedValue("Document.VendorPriceList.EmptyRef"),
				Object.Partner),
			DoNotCheckTheMatchedPartnerItem));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure PriceTreePartnerProductsOnChange(Item)
	
	CurrentRow = Items.PriceTree.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("CheckMatchedPartnerProducts",
		BatchProcessingOfTablePartClientServer.GetValidationStructureOfMatchedSupplierProductInTSLine(
			New Structure(
				"Ref,Partner",
				PredefinedValue("Document.VendorPriceList.EmptyRef"),
				Object.Partner),
			DoNotCheckTheMatchedPartnerItem));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	If UseItemPackages Then
		TypesOfPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject);
		ChangePackagesByTypeOfPrices(CurrentRow);
	EndIf;
	
	CurrentRow.RowMapped = ValueIsFilled(CurrentRow.Products);
	
	MarkDuplicatesOfTablePart();
	
EndProcedure
 
&AtClient
Procedure ChangePackagesByTypeOfPrices(CurrentRow)
	ChangePackagesByTypeOfPricesOnServer(CurrentRow.GetID());
EndProcedure

&AtServer
Procedure ChangePackagesByTypeOfPricesOnServer(RowID)

	TypesOfPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject);
	CurrentRow = PriceTree.FindByID(RowID);
	For Each PriceKind In TypesOfPrices Do
		ColumnNamePackaging = "Package" + PriceKind.ColumnName;
		If CurrentRow[ColumnNamePackaging] <> CurrentRow.Package Then
			CurrentRow[ColumnNamePackaging] = CurrentRow.Package;
			PriceTreePackagingWhenChangedOnServer(RowID, ColumnNamePackaging);
		EndIf;
	EndDo;
	
EndProcedure

// Parameters:
//   Item - FormField - 
&AtClient
Procedure PriceTreePriceWhenCustomerChanges(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName  = StrReplace(Item.Name, "PriceTree", "");
	If StrFind(CurColumnName, "ChangePercentage" + "PriceKind") Then
		CurColumnName = StrReplace(CurColumnName, "ChangePercentage" + "PriceKind", "PriceKind");
		CurrentData[CurColumnName] = Round(
			CurrentData["OldPrice" + CurColumnName]
			*((CurrentData["ChangePercentage" + CurColumnName] / 100) + 1), 15, 2);
	EndIf;
	
	ColumnNamePackaging = StrReplace(
		StrReplace(Item.Name, "ChangePercentage" + "PriceKind", "PriceKind"), "PriceTree" + "PriceKind", "Package" + "PriceKind");
		
	If StrFind(CurColumnName, "AmountOfChange" + "PriceKind") Then
		CurColumnName = StrReplace(CurColumnName, "AmountOfChange" + "PriceKind", "PriceKind");
		CurrentData[CurColumnName] = CurrentData["OldPrice" + CurColumnName] + CurrentData["AmountOfChange" + CurColumnName];
		If CurrentData["OldPrice" + CurColumnName] <> 0 Then
			CurrentData["ChangePercentage"+CurColumnName] = CurrentData[CurColumnName] / CurrentData["OldPrice" + CurColumnName] * 100;
		Else
			CurrentData["ChangePercentage"+CurColumnName] = 0;
		EndIf;
		ColumnNamePackaging = StrReplace(StrReplace(Item.Name, "AmountOfChange" + "PriceKind", "PriceKind"), "PriceTree" + "PriceKind", "Package" + "PriceKind");
	EndIf;
	
	CurrentRow = PriceTree.FindByID(CurrentData.GetID());
	
	CurrentData["ChangedManually"+CurColumnName] = True;
	CurrentData["TheCostOfTheChanged"] = True;
	
	If CurrentData["OldPrice"+CurColumnName] <> 0 Then
		CurrentData["ChangePercentage"+CurColumnName] = Round(
			100 * (CurrentData[CurColumnName]
			       - CurrentData["OldPrice"+CurColumnName]) / CurrentData["OldPrice"+CurColumnName],5,2);
	Else
		CurrentData["ChangePercentage"+CurColumnName] = 0;
	EndIf;
	
EndProcedure

// Parameters:
//   Item - FormField - 
&AtClient
Procedure PriceTreePackagingWhenChangingClient(Item)
	
	CurrentData = Items.PriceTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurColumnName = StrReplace(Item.Name, "PriceTree", "");

	PriceTreePackagingWhenChangedOnServer(CurrentData.GetID(), CurColumnName);
	
EndProcedure

&AtServer
Procedure PriceTreePackagingWhenChangedOnServer(Id, CurColumnName)
	SettingPricesServer.PriceTreePackageCurrencyOnChange(ThisObject, Id, CurColumnName);
EndProcedure

// Parameters:
//   Item - FormField - 
&AtClient
Procedure Attachable_PriceTreePriceWhenChanged(Item)
	
	Changed_Price = True;
	PriceTreePriceWhenCustomerChanges(Item);
	
EndProcedure

// Parameters:
//   Item - FormField - 
&AtClient
Procedure Attachable_PriceTreePackagingWhenChanging(Item)

	PriceTreePackagingWhenChangingClient(Item);

EndProcedure

&AtClient
Procedure PriceTreePartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.PriceTree.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	If Items.Steps.CurrentPage = Items.Step1 Then

		ClearMessages();
		If Not CheckFilling() Then
			Return;
		EndIf;
		
		Try
			ProductNameFilledIn = ValueIsFilled(SpreadsheetDocument.Area("R2C1").Text)
				                           Or ValueIsFilled(SpreadsheetDocument.Area("R2C2").Text);
		Except
			CommonClient.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
		
		If Not ProductNameFilledIn Then
			ShowMessageBox(Undefined, NStr("vi = 'Cần sao chép các cột vào bảng từ tệp ngoài.';
											|ru = 'Необходимо скопировать колонки в таблицу из внешнего файла.';
											|en = 'You must copy columns to the table from an external file.'; fa = 'You must copy columns to the table from an external file.';
											|it = 'È necessario copiare le colonne nella tabella dal file esterno.';
											|pl = 'Należy skopiować kolumny do tablicy z pliku zewnętrznego.';
											|tr = 'Sütunları harici bir dosyadan tabloya kopyalamanız gerekmektedir.'"));
			Return;
		EndIf;
		
		If MapCatalogs Then
			ClearMessages();
			Status(NStr("vi = 'Đang thực hiện so sánh dữ liệu đã nhập
			                     |với dữ liệu của cơ sở thông tin. Xin vui lòng chờ trong giây lát...';
			                     |ru = 'Осуществляется сопоставление введенных данных
			                     |с данными информационной базы. Пожалуйста подождите...';
			                     |en = 'Mapping entered data
			                     |with infobase data. Please wait...'; fa = 'Mapping entered data
			                     |with infobase data. Please wait...';
			                     |it = 'Viene eseguita l''associazione dei dati inseriti 
			                     |ai dati del database informatico. Attendere prego...';
			                     |pl = 'Odbywa się zestawienie wprowadzonych danych
			                     |z danymi bazy informacyjnej. Proszę czekać...';
			                     |tr = 'Girilen verilerin bilgi tabanındaki verilerle
			                     |eşleştirmesi gerçekleştirilmektedir. Lütfen bekleyin...'"),,,PictureLib.Information32);
			MatchTableDocumentDataWithSupplierProducts();
		EndIf;
		
		Items.Steps.CurrentPage = Items.Step2;
		
	ElsIf Items.Steps.CurrentPage = Items.Step2 Then
		
		ClearMessages();
		
		SupplierProductsUpdated = True;
		
		If UsePartnersProducts Then
			SupplierProductsUpdated = RecordSupplierProducts();
		EndIf;
	
		If SupplierProductsUpdated And (RegisterOnlyTheRecognizedItem Or CheckFilling()) Then
			
			Items.Steps.CurrentPage = Items.Step3;
			
		EndIf;
		
	EndIf;
	
	SetCurPageOfNavigationBar();
	
EndProcedure

&AtClient
Procedure ProcessUploadResultWhenAnsweringQuestion(Result, AdditionalParameters) Export
	If Result = Undefined Or Result.Result = "MoreDetails" Then
		Return;
	EndIf;
	
	ClearMessages();
	Items.Steps.CurrentPage = Items.Step3;
	SetCurPageOfNavigationBar();
EndProcedure

&AtClient
Procedure Back(Command)
	
	If Items.Steps.CurrentPage = Items.Step2 Then
		
		Items.Steps.CurrentPage = Items.Step1;
		
	ElsIf Items.Steps.CurrentPage = Items.Step3 Then
		
		Items.Steps.CurrentPage = Items.Step2;
		
	EndIf;
	
	SetCurPageOfNavigationBar();
	
EndProcedure

&AtClient
Procedure Help(Command)
	
	OpenFormHelp();
	
EndProcedure

&AtClient
Procedure Done(Command)
	
	ClearMessages();
	
	EndAssistant();
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close();

EndProcedure

&AtClient
Procedure SelectPriceTypes(Command)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Partner", Object.Partner);
	OpeningParameters.Insert("SelectedTypesOfPrices", SettingPricesClientServer.SelectedTypesOfPrices(ThisObject));
	
	OpenForm(
		"DataProcessor.ImportVendorPricesFromFile.Form.SelectionOfVendorPriceTypesForm",
		OpeningParameters,
		ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreePartnerProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PartnerProducts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.ProductsQuantityForSelection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue 	= New DataCompositionField("RegisterOnlyTheRecognizedItem");
	ItemFilter.ComparisonType 		= DataCompositionComparisonType.Equal;
	ItemFilter.RightValue	= False;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Green);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<sẽ tạo khi ghi nhận>';
													|ru = '<будет создана при регистрации>';
													|en = '<will be created on registration>'; fa = '<will be created on registration>';
													|it = '<sarà creata al momento della registrazione>';
													|pl = '<będzie utworzona podczas rejestracji>';
													|tr = '<kayıt sırasında oluşturulacaktır>'"));
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreePartnerProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.PartnerProducts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.ProductsQuantityForSelection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue 	= New DataCompositionField("RegisterOnlyTheRecognizedItem");
	ItemFilter.ComparisonType 		= DataCompositionComparisonType.Equal;
	ItemFilter.RightValue	= True ;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<sẽ không tạo khi ghi nhận>';
													|ru = '<не будет создана при регистрации>';
													|en = '<will not be created on registration>'; fa = '<will not be created on registration>';
													|it = '<non sarà creata durante la registrazione>';
													|pl = '<nie będzie utworzono podczas rejestracji>';
													|tr = '<kayıt sırasında oluşturulmayacaktır>'"));

	If GetFunctionalOption("UsePartnersProducts") Then
	
		//

		Item = ConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.PriceTreePartnerProducts.Name);

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("PriceTree.PartnerProducts");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("PriceTree.ProductsQuantityForSelection");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<Cần so sánh thủ công>';
														|ru = '<Необходимо сопоставить вручную>';
														|en = '<To be mapped manually>'; fa = '<To be mapped manually>';
														|it = '<Necessario effettuare associazione manuale>';
														|pl = '<Należy dopasować ręcznie>';
														|tr = '<Manuel olarak eşleştirilmelidir>'"));

	Else
		
		//

		Item = ConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.PriceTreeProducts.Name);

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("PriceTree.Products");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

		Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<Cần so sánh thủ công>';
														|ru = '<Необходимо сопоставить вручную>';
														|en = '<To be mapped manually>'; fa = '<To be mapped manually>';
														|it = '<Necessario effettuare associazione manuale>';
														|pl = '<Należy dopasować ręcznie>';
														|tr = '<Manuel olarak eşleştirilmelidir>'"));
		
	EndIf;
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreePartnerProducts.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ThePriceTreeName.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.ProductNameIsDifferent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", WebColors.LightGoldenRod);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreePartnerProducts.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreeSKU.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.ProductIDIsDifferent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", WebColors.LightGoldenRod);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "PriceTree" + "Characteristic", "PriceTree.ItemVariantsAreUsed");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreeProducts.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTreeCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTree.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsePartnersProducts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<bỏ qua khi ghi nhận>';
													|ru = '<пропущена при регистрации>';
													|en = '<skipped during registration>'; fa = '<skipped during registration>';
													|it = '<omessa durante la registrazione>';
													|pl = '<pominięta przy rejestracji>';
													|tr = '<kayıt sırasında atlandı>'"));
	
EndProcedure

&AtClient
Procedure SettingUpPriceRegistration(Command)
	FormParameters = New Structure();
	FormParameters.Insert("RegisterChangedPrices",					RegisterChangedPrices);
	FormParameters.Insert("RegisterOnlyTheRecognizedItem",	RegisterOnlyTheRecognizedItem);
	
	OpenForm(
		"DataProcessor.ImportVendorPricesFromFile.Form.PriceRegistrationSetupForm",
		FormParameters,
		ThisObject,,,, New CallbackDescription("SettingUpPriceRegistrationCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure SettingUpPriceRegistrationCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	RegisterChangedPrices				 = Result.RegisterChangedPrices;
	RegisterOnlyTheRecognizedItem = Result.RegisterOnlyTheRecognizedItem;
	
	SetSelectionByProduct_();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceForOrder()
	
	// Order packaging not found
	
	For Each TSRow In SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject) Do
		
		ColumnNamePackagingFilledIn = "PriceTree.PackageIsFilledIn" + TSRow.ColumnName;
		ColumnNameOrderPackaging    = "PriceTree" + "OrderPackage"    + TSRow.ColumnName;
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(ColumnNameOrderPackaging);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ColumnNamePackagingFilledIn);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("PriceTree.OrderPackage" + TSRow.ColumnName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("PriceTree.Products" + TSRow.ColumnName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không tìm thấy bộ đóng gói>';
														|ru = '<Упаковка не найдена>';
														|en = '<Packaging unit not found>'; fa = '<Packaging unit not found>';
														|it = '<Imballaggio non trovato>';
														|pl = '<Nie znaleziono opakowania>';
														|tr = '<Paketleme ünitesi bulunmadı>'"));
		
	EndDo;

EndProcedure

#Region Other

&AtServer
Procedure UpdatePriceViewColumns(ValueSelected)
	
	SettingPricesServer.ReReadSelectedPrices(ThisObject);
	
	For Each TSRow In SelectedPrices Do
		TSRow.Selected_5 = Not ValueSelected.Find(TSRow.Ref) = Undefined;
	EndDo;
	
	FillServiceColumnsOfPriceTypes();
	
	InitializeTableDocument();
	SettingPricesServer.BuildPriceTree(ThisObject);
	
EndProcedure

&AtServer
Procedure FillServiceColumnsOfPriceTypes()

	ColumnNumber = 3;
	For Each TSRow In SelectedPrices Do
		
		TSRow.NameSearch = Upper(StrReplace(TSRow.Description, " ", ""));
		If TSRow.Selected_5 Then
			TSRow.MXLColumnName = ColumnNumber;
			ColumnNumber = ColumnNumber + 1;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializeTableDocument()
	
	Template = Documents.VendorPriceList.GetTemplate("ImportPrices");
	
	SpreadsheetDocument.Clear();
	
	ProductArea = Template.GetArea("OwnGoods");
	SpreadsheetDocument.Join(ProductArea);
	
	For Each TSRow In SelectedPrices Do
		
		If Not TSRow.Selected_5 Then
			Continue;
		EndIf;
		PriceViewArea = Template.GetArea("PriceKind");
		PriceViewArea.Parameters.PriceKind = TSRow.Ref;
		PriceViewArea.Parameters.MinParty = StrTemplate(NStr("vi = 'Lô hàng tối thiểu %1';
															|ru = 'Мин. партия %1';
															|en = 'Min. delivery lot %1'; fa = 'Min. delivery lot %1';
															|it = 'Мин. партия %1';
															|pl = 'Min. delivery lot %1';
															|tr = 'Min. lot %1'"), TSRow.Ref);
		
		SpreadsheetDocument.Join(PriceViewArea);
		
		If UseItemPackages Then
			OrderPackagingArea = Template.GetArea("OrderPackage");
			OrderPackagingArea.Parameters.OrderPackage = StrTemplate(NStr("vi = 'Đóng gói đơn hàng %1';
																			|ru = 'Упаковка заказа %1';
																			|en = 'Order packaging unit %1'; fa = 'Order packaging unit %1';
																			|it = 'Упаковка заказа %1';
																			|pl = 'Order packaging unit %1';
																			|tr = '%1 sipariş paketleme ünitesi'"), TSRow.Ref);
			SpreadsheetDocument.Join(OrderPackagingArea)
		EndIf;
		
	EndDo;
	
	SpreadsheetDocument.FixedTop = 1;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfChoiceOfTypesOfPrices()
	Items.SelectPriceTypes.Enabled = ValueIsFilled(Object.Partner);
EndProcedure

&AtServer
Procedure SetSelectionByProduct_()
	
	Items.PriceTree.RowFilter = Undefined;
	
	FilterParameters = New Structure();
	
	If ProductsDisplayOption = 1 Then
		FilterParameters.Insert("RowMapped", False);
	ElsIf ProductsDisplayOption = 2 Then
		FilterParameters.Insert("IsDuplicate", True);
	ElsIf ProductsDisplayOption = 3 Then
		FilterParameters.Insert("RowMapped", True);
		FilterParameters.Insert("IsDuplicate", False);
	EndIf;
	
	If ShowChangedPrices <> 0 Then
		FilterParameters.Insert("TheCostOfTheChanged", True);
	EndIf;

	Items.PriceTree.RowFilter = New FixedStructure(FilterParameters);
	
EndProcedure

&AtClient
Procedure ShowChangedPricesOnChange(Item)
	SetSelectionByProduct_();
EndProcedure

&AtServer
Procedure LinkProductsToSupplierProductsServer(Cancel)
	
	PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Object.Goods, Cancel);
	
EndProcedure

&AtClient
Procedure EndAssistant()
	
	Status(NStr("vi = 'Đang tạo chứng từ
	                     |ghi nhận đơn giá của nhà cung cấp. Vui lòng đợi...';
	                     |ru = 'Осуществляется создание документа
	                     |регистрации цен поставщика. Пожалуйста подождите...';
	                     |en = 'Creating a document
	                     |for registration of vendor prices. Please wait...'; fa = 'Creating a document
	                     |for registration of vendor prices. Please wait...';
	                     |it = 'La creazione del documento
	                     |di registrazione di prezzi del fornitore è in corso. Attendere prego...';
	                     |pl = 'Odbywa się tworzenie dokumentu 
	                     |rejestracji cen dostawcy. Proszę czekać...';
	                     |tr = 'Tedarikçi fiyat belgesi
	                     |kaydı oluşturulmaktadır. Lütfen bekleyin...'"),,,PictureLib.Information32);
	
	Object.Goods.Clear();
	
	For Each TSRow In PriceTree Do
		
		For Each PriceKind In SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject) Do
			
			NewPrice = TSRow[PriceKind.ColumnName];
			ChangePercentage = TSRow["ChangePercentage" + PriceKind.ColumnName];
			ThereAreErrorsInLine = TSRow["IsDuplicate"] Or Not TSRow["RowMapped"];
			
			If 
				NewPrice = 0
				Or (RegisterChangedPrices And ChangePercentage = 0) 
				Or (RegisterOnlyTheRecognizedItem And ThereAreErrorsInLine)
				Then
				Continue;
			EndIf;
			
			NewRow = Object.Goods.Add();
			FillPropertyValues(NewRow, TSRow);
			If UseItemPackages Then
				NewRow.Package = TSRow["Package" + PriceKind.ColumnName];
				NewRow.OrderPackage = TSRow["OrderPackage" + PriceKind.ColumnName];
			EndIf;
			NewRow.NewPrice = NewPrice;
			NewRow.VendorPriceKind = PriceKind.Ref;
			NewRow.MinimumDeliveryLot = TSRow["MinimumDeliveryLot" + PriceKind.ColumnName];
			
		EndDo;
		
	EndDo;
	
	LinkProductsToSupplierProductsServer(False);

	PriceRegistrationDocument = CreateSupplierProductPriceRegistrationDocument();
	If PriceRegistrationDocument <> Undefined Then
		URL = GetURL(PriceRegistrationDocument);
		ShowUserNotification(NStr("vi = 'Đã tạo chứng từ';
									|ru = 'Создан документ';
									|en = 'Document is created'; fa = 'Document is created';
									|it = 'Documento creato';
									|pl = 'Utworzono dokument';
									|tr = 'Belge oluşturuldu'"),
										URL,
									PriceRegistrationDocument,
									PictureLib.Information32);
									Notify("Write_VendorPriceList",
									, 
									PriceRegistrationDocument);
		Done = True;
		Close();
	Else
		UpdateOldProductPricesOnServer();
		ShowMessageBox(Undefined, NStr("vi = 'Không thể tạo chứng từ ghi nhận đơn giá nhà cung cấp';
										|ru = 'Не удалось создать документ регистрации цен поставщика';
										|en = 'Failed to create vendor price registration document'; fa = 'Failed to create vendor price registration document';
										|it = 'Impossibile creare il documento di registrazione dei prezzi del fornitore';
										|pl = 'Nie udało się stworzyć dokument rejestracji cen dostawcy';
										|tr = 'Tedarikçi fiyat kaydı belgesi oluşturulamadı'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCurPageOfNavigationBar()
	
	If Items.Steps.CurrentPage = Items.Step1 Then
		Items.Navigation.CurrentPage = Items.StartNavigation;
		Items.TheBeginningOfTheNext.DefaultButton = True;
	ElsIf Items.Steps.CurrentPage = Items.Step3 Then
		Items.Navigation.CurrentPage = Items.EndNavigation;
		Items.TheEndIsReady.DefaultButton = True;
		
		InformationLineForRegisteredPrices = UpdateInformationLine();
				
	Else
		Items.Navigation.CurrentPage = Items.NavigationContinued;
		Items.ContinuedNext.DefaultButton = True;
	EndIf;
	
EndProcedure

&AtClient
Function UpdateInformationLine()

	FormattedString1 = ""; 
	FormattedString2 = ""; 
	FormattedString3 = ""; 
	FormattedString4 = ""; 
	FormattedString5 = ""; 

	DataForInformationLine = New Structure();
	DataForInformationLine.Insert("TotalRows", 			PriceTree.Count());
	DataForInformationLine.Insert("NoStringErrors", 		PriceTree.Count());
	DataForInformationLine.Insert("DuplicateRows", 		0);
	DataForInformationLine.Insert("UnrecognizedStrings", 	0);
	DataForInformationLine.Insert("SelectedPrices", 		0);
	
	For Each String In SelectedPrices Do
		If String.Selected_5 Then
			DataForInformationLine.SelectedPrices = DataForInformationLine.SelectedPrices + 1; 
		EndIf;
	EndDo;
		
	For Each String In PriceTree Do
		If String.IsDuplicate Or Not String.RowMapped Then
			
			DataForInformationLine.NoStringErrors = DataForInformationLine.NoStringErrors - 1;
			
			If String.IsDuplicate Then
				DataForInformationLine.DuplicateRows = DataForInformationLine.DuplicateRows + 1;
			EndIf;
			
			If Not String.RowMapped Then
				DataForInformationLine.UnrecognizedStrings = DataForInformationLine.UnrecognizedStrings + 1;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If RegisterOnlyTheRecognizedItem Then
		If DataForInformationLine.NoStringErrors = 0 Then
			FormattedString1 = New FormattedString(StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Sẽ không kết nhập đơn giá, bởi vì chưa nhận dạng được tất cả (%1) các dòng của bảng giá.';
																												|ru = 'Цены не будут загружены т.к. не распознаны все (%1) строки прайс листа.';
																												|en = 'The prices will not be imported as not all (%1) price list lines are recognized.'; fa = 'The prices will not be imported as not all (%1) price list lines are recognized.';
																												|it = 'Цены не будут загружены т.к. не распознаны все (%1) строки прайс листа.';
																												|pl = 'The prices will not be imported as not all (%1) price list lines are recognized.';
																												|tr = 'Fiyat listesinin tüm (%1) satırları tanınmadığından dolayı fiyatlar yüklenmeyecektir.'"),DataForInformationLine.TotalRows), New Font(,,True));
		Else
			FormattedString1 = New FormattedString(StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Sẽ kết nhập %1 trong số %2 dòng của bảng giá theo %3 dạng giá.';
																												|ru = 'Будет загружено %1 из %2 строк прайс листа по %3 видам цен.';
																												|en = '%1 of %2 price list lines for %3 price types will be imported.'; fa = '%1 of %2 price list lines for %3 price types will be imported.';
																												|it = 'Sari importeranno %1 di %2 righe del listino prezzo per %3 tipi di prezzo.';
																												|pl = 'Będzie pobrano %1 z %2 wierszy cennika wg %3 rodzajów cen.';
																												|tr = '%3 fiyat türüne göre %2 fiyat listesi satırından %1 yüklenecektir.'"),DataForInformationLine.NoStringErrors, DataForInformationLine.TotalRows, DataForInformationLine.SelectedPrices), New Font(,,True));
		EndIf;
	Else
		FormattedString1 = New FormattedString(StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Sẽ kết nhập %1 trong số %2 dòng của bảng giá theo %3 dạng giá.';
																											|ru = 'Будет загружено %1 из %2 строк прайс листа по %3 видам цен.';
																											|en = '%1 of %2 price list lines for %3 price types will be imported.'; fa = '%1 of %2 price list lines for %3 price types will be imported.';
																											|it = 'Sari importeranno %1 di %2 righe del listino prezzo per %3 tipi di prezzo.';
																											|pl = 'Będzie pobrano %1 z %2 wierszy cennika wg %3 rodzajów cen.';
																											|tr = '%3 fiyat türüne göre %2 fiyat listesi satırından %1 yüklenecektir.'"),DataForInformationLine.TotalRows, DataForInformationLine.TotalRows, DataForInformationLine.SelectedPrices), New Font(,,True));
	EndIf;
	
	If (DataForInformationLine.UnrecognizedStrings > 0 
		Or DataForInformationLine.DuplicateRows > 0) 
		And Not (DataForInformationLine.NoStringErrors = 0 And RegisterOnlyTheRecognizedItem) Then
		
		If DataForInformationLine.UnrecognizedStrings > 0 Then
			FormattedString2 = New FormattedString(StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = ' Chưa nhận dạng (%1)';
																												|ru = ' Нераспознанные (%1)';
																												|en = ' Unrecognized (%1)'; fa = ' Unrecognized (%1)';
																												|it = ' Non riconosciuti (%1)';
																												|pl = ' Nierozpoznane (%1)';
																												|tr = ' Tanınmayanlar (%1)'"), DataForInformationLine.UnrecognizedStrings), New Font(,,True));
		EndIf;
		
		If DataForInformationLine.DuplicateRows > 0 Then
			If DataForInformationLine.UnrecognizedStrings > 0 Then
				FormattedString3 = New FormattedString(StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = ' và trùng lặp (%1)';
																													|ru = ' и дублирующие (%1)';
																													|en = ' and duplicating (%1)'; fa = ' and duplicating (%1)';
																													|it = ' e duplicati (%1)';
																													|pl = ' i dublujące (%1)';
																													|tr = ' ve kopyalananlar (%1)'"), DataForInformationLine.DuplicateRows), New Font(,,True));
			Else
				FormattedString3 = New FormattedString(StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = ' Trùng lặp (%1)';
																													|ru = ' Дублирующие (%1)';
																													|en = ' Duplicating (%1)'; fa = ' Duplicating (%1)';
																													|it = ' Duplicati (%1)';
																													|pl = ' Dublujące (%1)';
																													|tr = ' Kopyalananlar (%1)'"), DataForInformationLine.DuplicateRows), New Font(,,True));
			EndIf;
		EndIf;

		If RegisterOnlyTheRecognizedItem Then
			FormattedString4 = New FormattedString(NStr("vi = ' dòng bị loại trừ khỏi kết nhập.';
														|ru = ' строки исключены из загрузки.';
														|en = ' lines excluded from import.'; fa = ' lines excluded from import.';
														|it = ' righe escluse dall''impotrazione.';
														|pl = ' wiersze są wykluczone z pobierania.';
														|tr = ' satırlar yükleme dışında tutuldu.'"), New Font(,,True));
		Else
			FormattedString4 = New FormattedString(NStr("vi = ' dòng cũng sẽ được kết nhập.';
														|ru = ' строки будут также загружены.';
														|en = ' the lines will also be imported.'; fa = ' the lines will also be imported.';
														|it = ' строки будут также загружены.';
														|pl = ' the lines will also be imported.';
														|tr = ' satırlar da yüklenecektir.'"), New Font(,,True));
		EndIf;

		
	EndIf;
	
	FormattedString5 = New FormattedString(NStr("vi = ' Nếu cần, hãy thêm ghi chú khi thay đổi đơn giá.';
												|ru = ' При необходимости, добавьте комментарий к изменению цен.';
												|en = ' If necessary, add a comment to the price change.'; fa = ' If necessary, add a comment to the price change.';
												|it = ' In caso di necessità, aggiungere i commenti alla modifica dei prezzi.';
												|pl = ' W razie konieczności, dodaj komentarz do zmiany cen.';
												|tr = ' Gerekmesi durumunda fiyat değişikliğine yorum ekleyin.'"), New Font(,,True));

	Return New FormattedString(FormattedString1, 
										FormattedString2, 
										FormattedString3,
										FormattedString4,
										FormattedString5);
	
EndFunction

&AtServer
Procedure UpdateOldProductPricesOnServer()
	
	DataCache = Undefined;
	
	ProductsTable = SettingPricesServer.GoodsTable(ThisObject, DataCache);
	SettingPricesServer.LoadOldPricesOfSupplierProducts(ThisObject, ProductsTable, DataCache);
	
EndProcedure

&AtServer
Procedure PriceTreeCharacteristicOnChangeServer(RowID, CalculatePrices = True)
	
	SettingPricesServer.PriceTreeCharacteristicOnChange(ThisObject, RowID);
	
EndProcedure

&AtServer
Procedure PriceTreeProductsOnChangeServer(RowID)
	
	CurrentRow = PriceTree.FindByID(RowID);
	
	TypesOfPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject);
	For Each PriceKind In TypesOfPrices Do
		
		ColumnName         = PriceKind.ColumnName;
		ColumnNamePackaging = "Package" + ColumnName;
		
		If UseItemPackages And ValueIsFilled(CurrentRow[ColumnNamePackaging]) Then
			CurrentRow[ColumnNamePackaging] = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		EndIf;
		
	EndDo;
	
	DataCache = SettingPricesServer.InitializeDataCacheStructure();
	
	If ValueIsFilled(CurrentRow.Products) Then
		
		Query = New Query("
		|SELECT
		|	CatalogProducts.UnitOfMeasure AS UnitOfMeasure,
		|	CatalogProducts.PriceGroup    AS PriceGroup,
		|	CatalogProducts.SKU          AS SKU,
		|	CASE
		|		WHEN CatalogProducts.UseVariants
		|		IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|		   VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
		|		   VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
		|		THEN TRUE
		|	ELSE FALSE END AS ItemVariantsAreUsed
		|FROM
		|	Catalog.Products AS CatalogProducts
		|WHERE
		|	CatalogProducts.Ref = &Products
		|");
		
		If UseItemPackages Then
			
			Query.Text = Query.Text + "
			|;
			|SELECT
			|	ItemsPrices.Characteristic    AS Characteristic,
			|	ItemsPrices.VendorPriceKind AS PriceKind,
			|	ItemsPrices.Package          AS Package
			|FROM
			|	InformationRegister.ItemsPricesOfVendor.SliceLast(&DocumentDate,
			|	                                                          Products = &Products
			|	                                                          AND VendorPriceKind IN (&TypesOfPrices)) AS ItemsPrices
			|";
			
			Query.SetParameter("TypesOfPrices",       SettingPricesClientServer.SelectedTypesOfPrices(ThisObject));
			Query.SetParameter("DocumentDate", BegOfDay(Object.Date) - 1);
			
		EndIf;
		
		Query.SetParameter("Products", CurrentRow.Products);
		
		ResultsArray = Query.ExecuteBatch();
		
		QueryResult = ResultsArray[0]; // QueryResult
		SelectionOfProducts = QueryResult.Select();
		
		If SelectionOfProducts.Next() Then
			FillPropertyValues(CurrentRow, SelectionOfProducts,,"SKU");
		EndIf;
		
		If UseItemPackages Then
				QueryResult = ResultsArray[1]; // QueryResult
				PackageSelection = QueryResult.Select();
			While PackageSelection.Next() Do
				CurrentRow["Package" + SettingPricesServer.ColumnNameByPriceType(PackageSelection.PriceKind, DataCache)] = PackageSelection.Package;
			EndDo;
		EndIf;
		
	Else
		
		CurrentRow.UnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		
	EndIf;
	
	// Loading old prices and percentage changes
	ValueTable = SettingPricesServer.CreateProductsTable(True);//ValueTable
	For Each PriceTypeLine In SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject) Do
		
		ColumnName = PriceTypeLine.ColumnName;
		ColumnNamePackaging = "Package" + ColumnName;
		
		NewRow = ValueTable.Add();
		NewRow.PartnerProducts = CurrentRow.PartnerProducts;
		NewRow.Products           = CurrentRow.Products;
		NewRow.Characteristic         = CurrentRow.Characteristic;
		NewRow.PriceKind                = PriceTypeLine.Ref;
		NewRow.Price                   = CurrentRow[ColumnName];
		If UseItemPackages Then
			NewRow.Package = CurrentRow[ColumnNamePackaging];
		EndIf;
		
	EndDo;
	
	SettingPricesServer.LoadOldPricesOfProducts(ThisObject, ValueTable, DataCache);
	
EndProcedure

&AtServer
Function CreateSupplierProductPriceRegistrationDocument()
	
	DataProcessorObject = FormAttributeToValue("Object");
	PriceRegistrationDocument = DataProcessorObject.CreateSupplierProductPriceRegistrationDocument(RegisterChangedPrices);
	ValueToFormAttribute(DataProcessorObject, "Object");
	Return PriceRegistrationDocument;
	
EndFunction

&AtServer
Procedure MatchTableDocumentDataWithSupplierProducts()
	
	PriceTree.Clear();
	
	// Preparing a table of products for comparison
	If UsePartnersProducts Then
		
		Query = New Query("
		|SELECT
		|	T.SKU      AS SKU,
		|	T.SKU      AS ProductIDSearch,
		|	T.Description AS Description,
		|	T.ItemName AS NameSearch,
		|	T.Products   AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.Package       AS Package,
		|	T.Ref         AS Ref
		|FROM
		|	Catalog.ProductCrossReferences AS T
		|WHERE
		|	NOT T.IsFolder
		|	AND NOT T.DeletionMark
		|	AND NOT T.Invalid
		|	AND T.Owner = &Partner
		|");
		
		Query.SetParameter("Partner", Object.Partner);
		
	Else
		
		Query = New Query("
		|SELECT
		|	T.SKU      AS SKU,
		|	T.SKU      AS ProductIDSearch,
		|	T.Description AS Description,
		|	T.Description AS NameSearch,
		|	T.Ref       AS Ref
		|FROM
		|	Catalog.Products AS T
		|WHERE
		|	NOT T.IsFolder
		|	AND NOT T.DeletionMark
		|");
		
	EndIf;
	
	PartnerProducts.Load(Query.Execute().Unload());
	
	For Each CurRow In PartnerProducts Do
		
		CurRow.ProductIDSearch = Upper(StrReplace(CurRow.SKU, " ", ""));
		CurRow.NameSearch = Upper(StrReplace(CurRow.NameSearch, " ", ""));
		
	EndDo;
	
	// Initializing the table to search for packages
	
	StringQualifiers = New StringQualifiers(100);
	RowDescription = New TypeDescription("String", ,StringQualifiers);
	
	PackingTable_ = New ValueTable;
	PackingTable_.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	PackingTable_.Columns.Add("Package", RowDescription);
	PackingTable_.Columns.Add("PriceKind", RowDescription);
	
	// Comparison of price list data with information database data
	ColumnArticle      = "C1";
	ColumnProducts = "C2";
	
	LineNumber = 2;
	StringNumber = Format(LineNumber, "NZ=0; NG=0");
	ProductNameFilledIn = ValueIsFilled(SpreadsheetDocument.Area("R" + Format(LineNumber, "NZ=0; NG=0") + ColumnArticle).Text)
		Or ValueIsFilled(SpreadsheetDocument.Area("R" + Format(LineNumber, "NZ=0; NG=0") + ColumnProducts).Text);
	
	While ProductNameFilledIn Do
		
		NewRow = PriceTree.Add();
		
		Try
			// 100 is the length of the supplier's item name
			NewRow.SKU = SpreadsheetDocument.Area("R" + StringNumber + ColumnArticle).Text;
			NewRow.NomenclatureName = Left(SpreadsheetDocument.Area("R" + StringNumber + ColumnProducts).Text, 100);
		Except
			Common.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
		
		TypesOfPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject);
		
		For Each TSRow In TypesOfPrices Do
			ProductPrice_ = SpreadsheetDocument.Area("R" + StringNumber + "C" + TSRow.MXLColumnName).Text;
			NewRow[TSRow.ColumnName] = ProductPrice_;
		EndDo;
		
		ArrayOfPartnerProducts = New Array();
		
		If ValueIsFilled(NewRow.SKU)
			And ValueIsFilled(NewRow.NomenclatureName) Then
			
			FilterParameters = New Structure(
					"ProductIDSearch, NameSearch",
					Upper(StrReplace(NewRow.SKU, " ", "")),
					Upper(StrReplace(NewRow.NomenclatureName, " ", "")));
					
			FoundRows = PartnerProducts.FindRows(FilterParameters);
			
			For Each FoundRow In FoundRows Do
				ArrayOfPartnerProducts.Add(FoundRow);
			EndDo;
			
		ElsIf ValueIsFilled(NewRow.SKU)
			 And Not ValueIsFilled(NewRow.NomenclatureName) Then
			
			FilterParameters = New Structure(
					"ProductIDSearch",
					Upper(StrReplace(NewRow.SKU, " ", "")));
					
			FoundRows = PartnerProducts.FindRows(FilterParameters);
			
			For Each FoundRow In FoundRows Do
				ArrayOfPartnerProducts.Add(FoundRow);
			EndDo;
			
		ElsIf Not ValueIsFilled(NewRow.SKU) 
			       And ValueIsFilled(NewRow.NomenclatureName) Then
			
			FilterParameters = New Structure(
					"NameSearch",
					Upper(StrReplace(NewRow.NomenclatureName, " ", "")));
					
			FoundRows = PartnerProducts.FindRows(FilterParameters);
			
			For Each FoundRow In FoundRows Do
				If ArrayOfPartnerProducts.Find(FoundRow) = Undefined Then
					ArrayOfPartnerProducts.Add(FoundRow);
				EndIf;
			EndDo;
			
		EndIf;
		
		If ArrayOfPartnerProducts.Count() = 1 Then
			
			NewRow.ProductsQuantityForSelection = 1;
			
			If UsePartnersProducts Then
				NewRow.PartnerProducts = ArrayOfPartnerProducts[0].Ref;
				NewRow.Products = ArrayOfPartnerProducts[0].Products;
				NewRow.Characteristic = ArrayOfPartnerProducts[0].Characteristic;
				NewRow.Package = ArrayOfPartnerProducts[0].Package;
				If UseItemPackages Then		
					TypesOfPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject);
					ChangePackagesByTypeOfPricesOnServer(NewRow.GetID());
				EndIf;
			Else
				NewRow.Products = ArrayOfPartnerProducts[0].Ref;
			EndIf;
			NewRow.ProductsMatchedAutomatically = True;
			
			If ValueIsFilled(NewRow.NomenclatureName) And NewRow.NomenclatureName <> ArrayOfPartnerProducts[0].Description Then
				NewRow.ProductNameIsDifferent = True;
			EndIf;
			
			If NewRow.SKU <> ArrayOfPartnerProducts[0].SKU Then
				NewRow.ProductIDIsDifferent = True;
			EndIf;
			
		ElsIf ArrayOfPartnerProducts.Count() > 1 Then
			
			NewRow.ProductsQuantityForSelection = ArrayOfPartnerProducts.Count();
			
			For Each CurItem In ArrayOfPartnerProducts Do
				
				FilterParameters = New Structure();
				FilterParameters.Insert("ProductIDSearch",      CurItem.ProductIDSearch);
				FilterParameters.Insert("NameSearch", CurItem.NameSearch);
				FilterParameters.Insert("SKU",           NewRow.SKU);
				FilterParameters.Insert("Description",      NewRow.NomenclatureName);
				FilterParameters.Insert("Ref",            CurItem.Ref);
				
				FoundRows = PartnerProducts.FindRows(FilterParameters);
				
				If FoundRows.Count() = 0 Then
					
					NewPartnerProducts = PartnerProducts.Add();
					NewPartnerProducts.NameSearch = CurItem.NameSearch;
					NewPartnerProducts.ProductIDSearch      = CurItem.ProductIDSearch;
					NewPartnerProducts.Description      = NewRow.NomenclatureName;
					NewPartnerProducts.SKU           = NewRow.SKU;
					NewPartnerProducts.Ref            = CurItem.Ref;
					
					If UsePartnersProducts Then
						NewPartnerProducts.Products   = CurItem.Products;
						NewPartnerProducts.Characteristic = CurItem.Characteristic;
						NewPartnerProducts.Package = CurItem.Package;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		ElsIf UsePartnersProducts Then
			
			// we will search by article and / or name by nomenclature
			FilterParameters = New Structure(
				"ProductIDSearch, NameSearch",
				Upper(TrimAll(NewRow.SKU)),
				Upper(TrimAll(NewRow.NomenclatureName)));
			
			FoundProducts = FindProductsFromCatalog(FilterParameters);
			
			If FoundProducts.Count() = 1 Then
				
				CurItem = FoundProducts[0];
				
				NewRow.Products = CurItem.Ref;
				If UseItemPackages Then
					TypesOfPrices = SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject);
					ChangePackagesByTypeOfPricesOnServer(NewRow.GetID());
				EndIf;
				NewRow.ProductsMatchedAutomatically = True;
				NewRow.RowMapped = True;
				
				If ValueIsFilled(NewRow.NomenclatureName) And NewRow.NomenclatureName <> CurItem.Description Then
					NewRow.ProductNameIsDifferent = True;
				EndIf;
				
				If NewRow.SKU <> CurItem.SKU Then
					NewRow.ProductIDIsDifferent = True;
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If NewRow.ProductsMatchedAutomatically
			And Not NewRow.ProductIDIsDifferent And
			  Not NewRow.ProductNameIsDifferent Then
			
			NewRow.RowMapped = True;
			
		EndIf;
		
		NewRow.ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(NewRow.Products);
		
		CountColumns = 0;
		For Each TSRow In SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject) Do
			ColumnNumberPrice           = Number(TSRow.MXLColumnName) + CountColumns;
			ColumnNumberMinBatch      = Number(TSRow.MXLColumnName) + CountColumns + 1;
			ColumnNumberOrderPackaging = Number(TSRow.MXLColumnName) + CountColumns + 2;
			
			ProductPrice_ = SpreadsheetDocument.Area("R" + StringNumber + "C" + ColumnNumberPrice).Text;
			NewRow[TSRow.ColumnName] = ProductPrice_;
			
			// The minimum batch is after the "Price" column
			MinimumBatch = SpreadsheetDocument.Area("R" + StringNumber + "C" + ColumnNumberMinBatch).Text;
			NewRow["MinimumDeliveryLot" + TSRow.ColumnName] = MinimumBatch;
			
			// Packaging - after the column "Min. batch"
			If UseItemPackages Then
				Package = SpreadsheetDocument.Area("R" + StringNumber + "C" + ColumnNumberOrderPackaging).Text;
				NewRow["PackageIsFilledIn" + TSRow.ColumnName] = ValueIsFilled(Package);
				NewRow["PackagingName" + TSRow.ColumnName] = String(Package);
				
				// Add a row to the table to search for packages
				StringPack = PackingTable_.Add();
				StringPack.Products = NewRow.Products;
				StringPack.Package = Package;
				StringPack.PriceKind = TSRow.ColumnName;
				
				CountColumns = CountColumns + 2;
			Else
				CountColumns = CountColumns + 1;
			EndIf;
			
		EndDo;
		
		LineNumber = LineNumber + 1;
		StringNumber = Format(LineNumber, "NZ=0; NG=0");
		
		Try
			ProductNameFilledIn = ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + ColumnArticle).Text)
			                               Or ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + ColumnProducts).Text);
		Except
			Common.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
		
	EndDo;
	
	PackingTable_ = FindPackages(PackingTable_);
	For Each StringPacking In PackingTable_ Do
		
		FilterParameters = New Structure();
		FilterParameters.Insert("Products", StringPacking.Products);
		
		FoundRows = PriceTree.FindRows(FilterParameters);
		
		For Each FoundRow In FoundRows Do
			FoundRow["OrderPackage" + StringPacking.PriceKind] = StringPacking.PackagingRef;
		EndDo;
		
	EndDo;
	
	UpdateOldProductPricesOnServer();
	
	SetSelectionByProduct_();
	
	MapCatalogs = False;
	
	MarkDuplicatesOfTablePart(); 
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	FilterParameters - Structure - selection by article or name
// Returns:
// 	ValueTable - with the results of the request
&AtServer
Function FindProductsFromCatalog(FilterParameters)
	
	Query = New Query("SELECT
	|	T.SKU AS SKU,
	|	T.Description AS Description,
	|	T.Ref AS Ref
	|FROM
	|	Catalog.Products AS T
	|WHERE
	|	NOT T.IsFolder
	|	AND NOT T.DeletionMark
	|	AND T.SKU = &ProductIDSearch
	|	AND T.Description = &NameSearch");

	If ValueIsFilled(FilterParameters.ProductIDSearch) Then
		Query.SetParameter("ProductIDSearch", FilterParameters.ProductIDSearch);
	Else
		Query.Text = StrReplace(Query.Text, "AND T.SKU = &ProductIDSearch", "");
	EndIf;
	
	If ValueIsFilled(FilterParameters.NameSearch) Then
		Query.SetParameter("NameSearch", FilterParameters.NameSearch);
	Else
		Query.Text = StrReplace(Query.Text, "AND T.Description = &NameSearch", "");
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

&AtServer
Procedure MarkDuplicatesOfTablePart(CurrentRow = Undefined)
	
	FilterStructure1 = New Structure;
	VerificationFields = New Structure("PartnerProducts, Products, Characteristic", "PartnerProducts", "Products","Characteristic");
	TabularSectionName = "PriceTree";
	
	StringValidationFields = "";
	For Each KeyAndValue In VerificationFields Do
		StringValidationFields = StringValidationFields + ", " + KeyAndValue.Key;
		FilterStructure1.Insert(KeyAndValue.Key);
	EndDo;
	StringValidationFields = Mid(StringValidationFields, 3);
	
	ValueSets = ThisObject[TabularSectionName].Unload(, StringValidationFields);//ValueTable
	ValueSets.Columns.Add("OccurrencesCount", Common.TypeDescriptionNumber(10));
	ValueSets.FillValues(1, "OccurrencesCount");
	ValueSets.GroupBy(StringValidationFields, "OccurrencesCount");
	
	For Each Item In ThisObject[TabularSectionName] Do
		Item.IsDuplicate = False;
	EndDo;
	
	If ValueSets.Count() <> ThisObject[TabularSectionName].Count() Then
		// There are duplicates
		For Each ValueSet In ValueSets Do
			If ValueSet.OccurrencesCount = 1 Then
				Continue;
			EndIf;
			
			StringValues = "";
			
			SkipSetOfValues = False;
			For Each KeyAndValue In VerificationFields Do
				If KeyAndValue.Value <> True Then
					If Not ValueIsFilled(ValueSet[KeyAndValue.Key]) Then
						Continue;
					EndIf;
				EndIf;
				
				StringValues = StringValues + ", """ + ValueSet[KeyAndValue.Key] + """";
			EndDo;
			If SkipSetOfValues Or StringValues = "" Then
				Continue;
			EndIf;
			
			StringValues = Mid(StringValues, 3);
			
			EntryNumber = 0;
			FillPropertyValues(FilterStructure1, ValueSet);
			DoubleLines = ThisObject[TabularSectionName].FindRows(FilterStructure1);
			For Each StringDouble In DoubleLines Do
//				Set duplicates for all but the first occurrence
				EntryNumber	= EntryNumber+1;
				If EntryNumber > 1 Then
					StringDouble.IsDuplicate	= True;
				EndIf; 
			EndDo;
			
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function RecordSupplierProducts()
	
	Cancel = False;
	
	ProductsArray = PriceTree.Unload(,"Products").UnloadColumn("Products"); // Array of CatalogRef.Products
	NomenclatureNames = Common.ObjectsAttributeValue(ProductsArray, "Description");
	
	For Each CurRow In PriceTree Do
		
		If CurRow.ItemVariantsAreUsed And Not ValueIsFilled(CurRow.Characteristic) Then
			
			ErrorText = NStr("vi = 'Chưa điền đặc tính mặt hàng tại dòng %LineNumber%';
							|ru = 'Не заполнено характеристика номенклатуры в строке %LineNumber%';
							|en = 'The item variant in the line %LineNumber% is not filled in'; fa = 'The item variant in the line %LineNumber% is not filled in';
							|it = 'Caratteristica dell''articolo nella riga %LineNumber% non è compilata';
							|pl = 'Nie wypełniono charakterystyki pozycji w wierszu %LineNumber%';
							|tr = '%LineNumber% satırındaki ürün varyantları doldurulmadı'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%", PriceTree.IndexOf(CurRow) + 1);
			
			Common.MessageToUser(
				ErrorText,
				,
				CommonClientServer.PathToTabularSection("PriceTree", PriceTree.IndexOf(CurRow)+1, "Characteristic"),
				,
				Cancel);
			
		EndIf;
		
		If Not RegisterOnlyTheRecognizedItem
			And Not ValueIsFilled(CurRow.PartnerProducts) 
			And Not ValueIsFilled(CurRow.NomenclatureName) Then
			
			If ValueIsFilled(CurRow.Products) Then
				
				CurRow.NomenclatureName = NomenclatureNames.Get(CurRow.Products);
				
			Else
				
				ErrorText = NStr("vi = 'Chưa điền tên gọi mặt hàng tại dòng %LineNumber%';
								|ru = 'Не заполнено наименование номенклатуры в строке %LineNumber%';
								|en = 'Item name is required in line %LineNumber%'; fa = 'Item name is required in line %LineNumber%';
								|it = 'Il nome dell''articolo nella riga %LineNumber% non è stato compilato';
								|pl = 'Nie wypełniono nazwę nomenklatury w wierszu %LineNumber%';
								|tr = '%LineNumber% satırındaki öğe tanımı doldurulmadı'");
				ErrorText = StrReplace(ErrorText, "%LineNumber%", PriceTree.IndexOf(CurRow) + 1);
				
				Common.MessageToUser(
					ErrorText,
					,
					CommonClientServer.PathToTabularSection("PriceTree", PriceTree.IndexOf(CurRow)+1, "NomenclatureName"),
					,
					Cancel);
					
			EndIf;
			
		EndIf;
		
		If UseItemPackages Then
			For Each TSRow In SettingPricesClientServer.SelectedRowsInPriceViewTable(ThisObject) Do
				
				If CurRow.Products.IsEmpty() 
					Or Not Common.ObjectAttributeValue(CurRow.Products, "UsePackages") Then
					Continue;
				EndIf;
				
				If Not ValueIsFilled(CurRow["OrderPackage" + TSRow.ColumnName]) And CurRow["PackageIsFilledIn" + TSRow.ColumnName] And ValueIsFilled(CurRow.Products) Then
					
					ErrorText = NStr("vi = 'Chưa điền bộ đóng gói đơn hàng trong dòng %LineNumber%';
									|ru = 'Не заполнена упаковка заказа в строке %LineNumber%';
									|en = 'Order packaging unit is required in row %LineNumber%'; fa = 'Order packaging unit is required in row %LineNumber%';
									|it = 'Non è stato compilato l''imballaggio nella riga %LineNumber%';
									|pl = 'Nie wypełniono opakowanie zamówienia w wierszu %LineNumber%';
									|tr = '%LineNumber% satırındaki sipariş paketleme ünitesi doldurulmadı'");
					ErrorText = StrReplace(ErrorText, "%LineNumber%", PriceTree.IndexOf(CurRow) + 1);
					
					Common.MessageToUser(
					ErrorText,
					,
					CommonClientServer.PathToTabularSection("PriceTree", PriceTree.IndexOf(CurRow)+1, "OrderPackage"  + TSRow.ColumnName),
					,
					Cancel);
					
				EndIf;
				
			EndDo;
		EndIf;
		
	EndDo;
	
	If Cancel Then
		Return False;
	EndIf;

	
	Return True;
	
EndFunction

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	DataCache = Undefined;
	GoodsTable = SettingPricesServer.GoodsTable(ThisObject, DataCache);
	TMCommonUse.NumberValueTable(GoodsTable, "LineNumber");
	
	PriceManagementSystem.CheckCorrectnessOfFillingInSupplierProductPriceSettingDocument(
		ThisObject.Object, GoodsTable, Cancel);
	
EndProcedure

&AtServer
Function FindPackages(PackingTable_)
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("PackingTable_", PackingTable_);
	Query.Text = 
		"SELECT
		|	PackingTable.Products AS Products,
		|	PackingTable.Package AS Package,
		|	PackingTable.PriceKind AS PriceKind
		|INTO TTPackingTable
		|FROM
		|	&PackingTable_ AS PackingTable
		|
		|INDEX BY
		|	Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTPackingTable.Products AS Products,
		|	TTPackingTable.Package AS Package,
		|	TTPackingTable.PriceKind AS PriceKind,
		|	MAX(ISNULL(PackagesAndUnitsOfMeasure.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))) AS PackagingRef
		|FROM
		|	TTPackingTable AS TTPackingTable
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
		|		ON (CASE
		|				WHEN TTPackingTable.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
		|					THEN TTPackingTable.Products = PackagesAndUnitsOfMeasure.Owner
		|				ELSE TTPackingTable.Products.PackagingGroup = PackagesAndUnitsOfMeasure.Owner
		|			END)
		|			AND TTPackingTable.Package = PackagesAndUnitsOfMeasure.Description
		|
		|GROUP BY
		|	TTPackingTable.Products,
		|	TTPackingTable.Package,
		|	TTPackingTable.PriceKind";
	
	PackingTable_ = Query.Execute().Unload();
	
	Return PackingTable_;
	
EndFunction

// Parameters:
// ValueSelected - CatalogRef.ProductCrossReferences
// AdditionalParameters - Structure
// 
&AtClient
Procedure ProcessResultOfSelectingPartnerProductName(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.CurrentRow.PartnerProducts = ValueSelected;
	
	PriceTreePartnerProductsOnChange(AdditionalParameters.FormItem);
	
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
