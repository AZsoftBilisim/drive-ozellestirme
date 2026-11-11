
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	UseStoreFormats = GetFunctionalOption("UseStoreFormats");
	If UseStoreFormats Then
		Items.PlanningObject.TypeRestriction = New TypeDescription("CatalogRef.StoreFormats");
		Items.PlanningObject.ChooseType = False;
		If Not ValueIsFilled(Object.PlanningObject) Then
			Object.PlanningObject = Catalogs.StoreFormats.EmptyRef();
		EndIf; 
	Else
		Items.GroupQuotaRecommended.Visible = False;
		Items.PlanningObject.Title = NStr("vi = 'Cửa hàng/kho bãi';
											|ru = 'Магазин/склад';
											|en = 'Store/warehouse'; fa = 'Store/warehouse';
											|it = 'Magazzino/deposito';
											|pl = 'Store/warehouse';
											|tr = 'Mağaza/ambar'");
		If Not ValueIsFilled(Object.PlanningObject) Then
			Object.PlanningObject = Catalogs.Warehouses.DefaultWarehouse();
		EndIf;
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	CreateTreeBasedOnCategoryTable();
	
	UpdateTotalsServer();
	UpdateRecommendedMetrics();
	
	Items.CategoryTreeUploadQuotasFromAFile.Enabled = Not ThisForm.ReadOnly;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ReFillCategories(CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	UpdateTotalsServer();
	UpdateRecommendedMetrics();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	CommonClient.ShowCommentEditingForm(Item.EditText, ThisForm, "Object.Comment");
EndProcedure

&AtClient
Procedure PlanningObjectOnChange(Item)
	UpdateRecommendedMetrics();
	ThereIsPlan = HavingPlan();
	If ThereIsPlan Then
		Object.PlanningObject = Items.PlanningObject.TypeRestriction.AdjustValue(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValidityStartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	Object.ValidityStartDate = BegOfMonth(Object.ValidityStartDate);
	ThereIsPlan = HavingPlan();
	If ThereIsPlan Then
		Object.ValidityStartDate = Undefined;
	EndIf;
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure CategoryTreeQuotaOnChange(Item)
	CurrentRow = Items.CategoryTree.CurrentData;
	Parent = CurrentRow.GetParent();
	If Parent<>Undefined Then
		UpdateParentQuota(Parent);
	EndIf;
	UpdateTotalsServer();
EndProcedure

&AtClient
Procedure CategoryTreeVariancePercentageOnChange(Item)
	CurrentRow = Items.CategoryTree.CurrentData;
	If CurrentRow.VariancePercentage > 100 Then
		WarningText = NStr("vi = 'Sai lệch không thể vượt quá 100%';
							|ru = 'Отклонение не может превышать 100%';
							|en = 'Variance cannot be more than 100%'; fa = 'Variance cannot be more than 100%';
							|it = 'La variazione non può superare il 100%';
							|pl = 'Odchylenie nie może przekraczać 100%';
							|tr = 'Sapma 100%''ü aşamaz'");
		ShowMessageBox(New CallbackDescription("CategoryTreeVariancePercentageOnChangeCompletion", ThisObject, New Structure("CurrentRow", CurrentRow)), WarningText);
        Return;
	EndIf;
	CategoryTreePercentageOfDeviationWhenChangingFragment(CurrentRow);
EndProcedure


// LongDesc
// 
// Parameters:
// 	AdditionalParameters - Structure - Contains:
//                           * CurrentRow - LineOfATabularSection -  
//
&AtClient
Procedure CategoryTreeVariancePercentageOnChangeCompletion(AdditionalParameters) Export
    
    CurrentRow = AdditionalParameters.CurrentRow;
    
    
    CurrentRow.VariancePercentage = 100;
    
    CategoryTreePercentageOfDeviationWhenChangingFragment(CurrentRow);

EndProcedure

&AtClient
Procedure CategoryTreePercentageOfDeviationWhenChangingFragment(Val CurrentRow)
    
    Parent = CurrentRow.GetParent();
    If Parent<>Undefined Then
        UpdateParentPercentage(Parent);
    EndIf;

EndProcedure

&AtClient
Procedure CategoryTreeBeforeRowChange(Item, Cancel)
	If TypeOf(Item.CurrentData.TypeCategoryBrand) = Type("CatalogRef.Brands")
		Or TypeOf(Item.CurrentData.TypeCategoryBrand) = Type("String") Then
		If Item.CurrentItem.Name = "CategoryTreeViewPresentation" Then
			Cancel = True;
			Return;
		EndIf;
	Else
		Cancel = True;
		Return;
	EndIf;
EndProcedure

&AtClient
Procedure CategoryTreeSelection(Item, RowSelected, Field, StandardProcessing)
	CurrentRow = Item.CurrentData;
	If CurrentRow<>Undefined Then
		If TypeOf(CurrentRow.TypeCategoryBrand) = Type("CatalogRef.ProductCategories")
			Or TypeOf(CurrentRow.TypeCategoryBrand) = Type("CatalogRef.ItemKinds") Then
			Items.CategoryTree.Expand(CurrentRow.GetID());
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure CategoryTreeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
EndProcedure

&AtClient
Procedure CategoryTreeBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	ShowQueryBox(
		New CallbackDescription("CategoryTreeBeforeDeleteRowCompletion", ThisObject), 
		NStr("vi = 'Xóa dòng?';
			|ru = 'Удалить строку?';
			|en = 'Remove the line?'; fa = 'Remove the line?';
			|it = 'Eliminare la riga?';
			|pl = 'Osunąć wiersz?';
			|tr = 'Satır silinsin mi?'"), 
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure CategoryTreeBeforeDeleteRowCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	CurrentRow = Items.CategoryTree.CurrentData;
	CurrentRowIndex = Items.CategoryTree.CurrentRow;
	
	If CurrentRow <> Undefined Then
		ReduceQuotaOfParentAfterDeletion(CurrentRow, CurrentRow.Quota);
		CurrentParent = CurrentRow.GetParent();
		If CurrentParent <> Undefined Then
			CurrentRow.VariancePercentage = 0;
			UpdateParentPercentage(CurrentParent, True);
			ParentIndex = CurrentParent.GetID();
			NumberOfAllowed = 1;
			RemoveParentRowIfNecessary(ParentIndex, NumberOfAllowed);
			If CurrentParent.GetItems().Count() <> 0 Then
				CurrentParent.GetItems().Delete(CurrentRow);
			EndIf;
		Else
			CategoryTree.GetItems().Delete(CurrentRow);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CategoryTreeAfterDeleteRow(Item)
	CategoryTreeAfterDeleteRowServer();
EndProcedure

&AtClient
Procedure ItemsCollectionOnChange(Item)
	
	If ValueIsFilled(Object.ItemsCollection) Then
	
		StartDate = CollectionOfProductsWhenChangedOnServer(Object.ItemsCollection);
		
		If ValueIsFilled(StartDate) 
			And (Not ValueIsFilled(Object.ValidityStartDate) 
			Or Object.ValidityStartDate < StartDate) Then
		
			Object.ValidityStartDate = StartDate;
		
		EndIf; 
	
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInWithCategories(Command)
	
	FillInWithCategoriesServer();
	
EndProcedure

&AtClient
Procedure FillInByDataOfAnotherFormat(Command)
	If Object.ProductCategories.Count()>0 Then
		Response = Undefined;

		ShowQueryBox(New CallbackDescription("FillInByDataOfAnotherFormatCompletion", ThisObject), NStr("vi = 'Phần bảng chứa dòng và sẽ được điền lại';
																										|ru = 'Табличная часть содержит строки и будет перезаполнена';
																										|en = 'Table contains rows and will be refilled'; fa = 'Table contains rows and will be refilled';
																										|it = 'La parte tabulare contiene le righe e verrà ricompilata';
																										|pl = 'Część tabelaryczna zawiera wiersze i zostanie wypełniona ponownie';
																										|tr = 'Tablo bölümü satırlar içermektedir ve yeniden doldurulacaktır'"), QuestionDialogMode.YesNo);
        Return;
	EndIf;
	FillInFragmentUsingDataOfDifferentFormat();
EndProcedure

&AtClient
Procedure FillInByDataOfAnotherFormatCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    FillInFragmentUsingDataOfDifferentFormat();

EndProcedure

&AtClient
Procedure FillInFragmentUsingDataOfDifferentFormat()
	
	OpenForm("Catalog.StoreFormats.ChoiceForm",,,,,, 
					New CallbackDescription("FillInFragmentUsingDataOfDifferentFormatCompletion", ThisObject), 
					FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure FillInFragmentUsingDataOfDifferentFormatCompletion(Result, AdditionalParameters) Export
	
	SelectedStoreFormat = Result;
	If SelectedStoreFormat = Undefined Then
		Return;
	Else
		FillInByDataOfAnotherFormatServer(SelectedStoreFormat);
		CreateTreeBasedOnCategoryTable();
		UpdateTotalsServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure ExpandTheTree(Command)
	TreeItems = CategoryTree.GetItems();
	For Each TreeItem In TreeItems Do
		LineID = TreeItem.GetID();
		Items.CategoryTree.Expand(LineID, True);
	EndDo;
EndProcedure

&AtClient
Procedure SetAVariancePercentageForAllLines(Command)
	Percent = 0;
	NumberEntryHeaderText = NStr("vi = 'Nhập % sai lệch';
								|ru = 'Введите % отклонения';
								|en = 'Enter variance, %'; fa = 'Enter variance, %';
								|it = 'Inserite il % di variazione';
								|pl = 'Wprowadź % odchylenia';
								|tr = '% sapma girin'");
	ShowInputNumber(New CallbackDescription("SetAVariancePercentageForAllLinesCompletion", ThisObject, New Structure("Percent", Percent)), Percent, NumberEntryHeaderText, 3, 0);
EndProcedure

&AtClient
Procedure SetAVariancePercentageForAllLinesCompletion(Number, AdditionalParameters) Export
    
    Percent = ?(Number = Undefined, AdditionalParameters.Percent, Number);
    
    
    If (Number <> Undefined) Then
        If Percent > 100 Then
            WarningText = NStr("vi = 'Sai lệch không thể vượt quá 100%';
								|ru = 'Отклонение не может превышать 100%';
								|en = 'Variance cannot be more than 100%'; fa = 'Variance cannot be more than 100%';
								|it = 'La variazione non può superare il 100%';
								|pl = 'Odchylenie nie może przekraczać 100%';
								|tr = 'Sapma 100%''ü aşamaz'");
            ShowMessageBox(Undefined, WarningText);
        Else
            TreeItems = CategoryTree.GetItems();
            SetPercentageToSubordinates(TreeItems, Percent);
        EndIf;
    EndIf;

EndProcedure

&AtClient
Procedure SetPercentageToSubordinates(TreeItems, Percent)
	For Each TreeItem In TreeItems Do
		TreeItem.VariancePercentage = Percent;
		SubordinateItems = TreeItem.GetItems();
		If SubordinateItems.Count() > 0 Then
			SetPercentageToSubordinates(SubordinateItems, Percent);
		EndIf;
	EndDo;	
EndProcedure
	
&AtClient
Procedure CollapseTheTree(Command)
	TreeItems = CategoryTree.GetItems();
	For Each TreeItem In TreeItems Do
		LineID = TreeItem.GetID();
		Items.CategoryTree.Collapse(LineID);
	EndDo;
EndProcedure

&AtClient
Procedure AddBrand(Command)
	CurRow = Items.CategoryTree.CurrentData;
	If CurRow = Undefined Then ShowMessageBox(Undefined, NStr("vi = 'Chỉ có thể thêm nhãn hiệu trực thuộc thể loại nào đó';
																|ru = 'Марку можно добавить только в подчинение какой-либо категории';
																|en = 'Brand can be added only on Category level'; fa = 'Brand can be added only on Category level';
																|it = 'Si può aggiungere il marchio solo in subordine a qualche categoria';
																|pl = 'Znak można dodać tylko jako podporządkowanie jakieś kategorii';
																|tr = 'Marka sadece bir kategorinin alt kategorisine eklenebilir'"));
	Else
		RowType = 0;
		If TypeOf(CurRow.TypeCategoryBrand) = Type("CatalogRef.ProductCategories") Then
			If Not CurRow.ThisIsCategoryGroup Then
				RowType = 1;
			EndIf;
		ElsIf TypeOf(CurRow.TypeCategoryBrand) = Type("CatalogRef.Brands")
			Or TypeOf(CurRow.TypeCategoryBrand) = Type("String") Then
			RowType = 2;
		EndIf;
		If RowType > 0 Then
			SelectedBrand = Undefined;

			OpenForm("Catalog.Brands.ChoiceForm", , ThisForm,,,, New CallbackDescription("AddBrandCompletion", ThisObject, New Structure("RowType", RowType)), FormWindowOpeningMode.LockOwnerWindow);
		Else
			ShowMessageBox(Undefined, NStr("vi = 'Chỉ có thể thêm nhãn hiệu trực thuộc thể loại nào đó';
											|ru = 'Марку можно добавить только в подчинение какой-либо категории';
											|en = 'Brand can be added only on Category level'; fa = 'Brand can be added only on Category level';
											|it = 'Si può aggiungere il marchio solo in subordine a qualche categoria';
											|pl = 'Znak można dodać tylko jako podporządkowanie jakieś kategorii';
											|tr = 'Marka sadece bir kategorinin alt kategorisine eklenebilir'"));
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure AddBrandCompletion(Result, AdditionalParameters) Export
    
    RowType = AdditionalParameters.RowType;
    
    
    SelectedBrand = Result;
    If SelectedBrand<>Undefined Then
        CurStringCollection = CategoryTree.FindByID(Items.CategoryTree.CurrentRow);
        If CurStringCollection<>Undefined Then
            If RowType = 1 Then
                // adding a subordinate to the current line
                ParentLevelRow = CurStringCollection;
            Else
                // adding a subordinate to the parent line
                ParentLevelRow = CurStringCollection.GetParent();
            EndIf;
            RowItems = ParentLevelRow.GetItems();
            If BrandHasAlreadyBeenAdded(ParentLevelRow.GetID(), SelectedBrand) Then
                ShowMessageBox(Undefined, NStr("vi = 'Đã thêm nhãn hiệu vào thể loại này';
												|ru = 'Марка уже добавлена в данной категории';
												|en = 'Brand has already been added to this category'; fa = 'Brand has already been added to this category';
												|it = 'Il marchio è stato già aggiunto in questa categoria';
												|pl = 'Znak już dodano do danej kategorii';
												|tr = 'Marka zaten bu kategoriye eklendi'"));
            Else
                NewRow = RowItems.Add();
                NewRow.TypeCategoryBrand = SelectedBrand;
                NewRow.Presentation = String(SelectedBrand);
                NewRow.Quota = 0;
                NewRow.VariancePercentage = 0;
                NewRow.PictureIndex = 2;
                UpdateParentPercentage(NewRow.GetParent());
            EndIf;
        EndIf;
    EndIf;

EndProcedure

&AtClient
Procedure EditCategoryTree(Command)
	CurrentData = Items.CategoryTree.CurrentData;
	If CurrentData <> Undefined Then
		Items.CategoryTree.ChangeRow();
	EndIf;
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure UploadQuotasFromAFile(Command)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "SetProductRangeQuotas.ProductCategories";
	ImportParameters.Title = NStr("vi = 'Kết nhập hạn mức danh điểm mặt hàng từ tệp';
									|ru = 'Загрузка квот ассортимента из файла';
									|en = 'Import product range quotas from file'; fa = 'Import product range quotas from file';
									|it = 'Download delle quote di assortimento dal file';
									|pl = 'Pobieranie kwot asortymentu z pliku';
									|tr = 'Dosyadan ürün çeşitliliği kotasının yüklenmesi'");
	
	Notification = New CallbackDescription("UploadQuotasFromAFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

EndProcedure

&AtClient
Procedure UpdateParentQuota(Parent)
	
	ParentItems1 = Parent.GetItems();
	QuotaTotal = 0;
	For Each ParentItem1 In ParentItems1 Do
		QuotaTotal = QuotaTotal+ParentItem1.Quota;
	EndDo;
	Parent.Quota = QuotaTotal;
	//
	ParentAbove = Parent.GetParent();
	If ParentAbove<>Undefined Then
		UpdateParentQuota(ParentAbove);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateParentPercentage(Parent, BeforeDeleteRow = False)
	
	ParentItems1 = Parent.GetItems();
	PercentageTotal = 0;
	SubordinateCount = 0;
	For Each ParentItem1 In ParentItems1 Do
		PercentageTotal = PercentageTotal + ParentItem1.VariancePercentage;
		SubordinateCount = SubordinateCount + 1;
	EndDo;
	If BeforeDeleteRow Then
		SubordinateCount = SubordinateCount - 1;
	EndIf;
	Parent.VariancePercentage =  ?(SubordinateCount = 0, 0, PercentageTotal / SubordinateCount);
	//
	ParentAbove = Parent.GetParent();
	If ParentAbove <> Undefined Then
		If BeforeDeleteRow Then
			ElementsBelow = ParentAbove.GetItems();
			If ElementsBelow.Count() > 1
				And ParentItems1.Count() > 1 Then
				UpdateParentPercentage(ParentAbove);
			Else
				// This line will also be deleted
				UpdateParentPercentage(ParentAbove, True);
			EndIf;
		Else
			UpdateParentPercentage(ParentAbove);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function HavingPlan()
	ThereIsPlan = False;
	If ValueIsFilled(Object.PlanningObject) And ValueIsFilled(Object.ValidityStartDate) Then
		ThereIsPlan = HavingPlanServer();
		If ThereIsPlan Then
			WarningText = NStr("vi = 'Đã lập chứng từ đặt hạn mức cho %1 đối với khuôn dạng được chọn.';
								|ru = 'На %1 для выбранного формата уже существует документ установки квот.';
								|en = 'Quota setting document already exists for the selected format on %1.'; fa = 'Quota setting document already exists for the selected format on %1.';
								|it = 'Al %1 per il formato selezionato esiste già un documento di impostazione delle quote.';
								|pl = 'Na %1 dla wybranego formatu już istnieje dokument ustawienia limitów ';
								|tr = 'Seçilen formatta ""%1"" için zaten bir kota yapılandırma belgesi mevcut.'")
			+ Chars.LF + NStr("vi = 'Có thể thiết lập hạn mức không nhiều hơn 1 lần mỗi tháng.';
								|ru = 'Установка квот может производиться не чаще 1 раза в месяц.';
								|en = 'Quotas can be set only once a month.'; fa = 'Quotas can be set only once a month.';
								|it = 'L''impostazione delle quote può essere effettuata non più di 1 volta al mese.';
								|pl = 'Ustawienia limitów można wykonywać nie częściej niż raz na miesiąc';
								|tr = 'Kotalar ayda bir defadan fazla yapılandırılamaz.'")
			+ Chars.LF + NStr("vi = 'Hãy chọn ngày hoặc khuôn dạng cửa hàng khác.';
								|ru = 'Выберите другую дату или формат магазинов.';
								|en = 'Select another date or retail format.'; fa = 'Select another date or retail format.';
								|it = 'Selezionate un''altra data oppure un formato dei negozi.';
								|pl = 'Wybierz inną datę lub format sklepów.';
								|tr = 'Farklı bir tarih veya mağaza formatı seçin.'");
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
									WarningText,
									Format(Object.ValidityStartDate,"DF = dd.MM.yyyy"));
			ShowMessageBox(,WarningText);
		EndIf;
	EndIf;
	Return ThereIsPlan;
EndFunction

&AtClient
Procedure RemoveParentRowIfNecessary(CurrentIndex, NumberOfAllowed)
	CurrentParent = CategoryTree.FindByID(CurrentIndex);
	If CurrentParent <> Undefined Then
		CurSubordinateElements = CurrentParent.GetItems();
		If CurSubordinateElements.Count() = NumberOfAllowed Then
			CurParentOfParent = CurrentParent.GetParent();
			If CurParentOfParent = Undefined Then
				ParentSSubordinatesOfParent = CategoryTree.GetItems();
				ParentSSubordinatesOfParent.Delete(CurrentParent);
				NumberOfAllowed = 0;
			Else
				ParentSSubordinatesOfParent = CurParentOfParent.GetItems();
				ParentSSubordinatesOfParent.Delete(CurrentParent);
				NumberOfAllowed = 0;
				IndexOfParentOfParent = CurParentOfParent.GetID();
				RemoveParentRowIfNecessary(IndexOfParentOfParent, NumberOfAllowed);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ReduceQuotaOfParentAfterDeletion(CurrentRow, DeductibleQuota)
	CurrentParent = CurrentRow.GetParent();
	If CurrentParent <> Undefined Then
		CurrentParent.Quota = CurrentParent.Quota-DeductibleQuota;
		ReduceQuotaOfParentAfterDeletion(CurrentParent, DeductibleQuota);
	EndIf;
EndProcedure

&AtServer
Procedure FillInByDataOfAnotherFormatServer(SelectedPlanningObject)
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Quotas.ProductCategory AS ProductCategory,
	|	Quotas.Brand AS Brand,
	|	Quotas.Quota AS Quota,
	|	Quotas.VariancePercentage AS VariancePercentage
	|FROM
	|	InformationRegister.ProductMixQuotas.SliceLast(&OnDate, PlanningObject = &PlanningObject) AS Quotas
	|WHERE
	|	Quotas.Period IN
	|			(SELECT
	|				MAX(K.Period)
	|			FROM
	|				InformationRegister.ProductMixQuotas AS K
	|			WHERE
	|				K.Period <=  &OnDate
	|				AND K.PlanningObject = &PlanningObject)";
	Query.SetParameter("PlanningObject", SelectedPlanningObject);
	Query.SetParameter("OnDate", Object.Date);
	Selection = Query.Execute().Select();
	ItemCategories = Object.ProductCategories;
	ItemCategories.Clear();
	While Selection.Next() Do
		NewRowOfCategories = ItemCategories.Add();
		FillPropertyValues(NewRowOfCategories,Selection);
	EndDo;
	Items.CategoryTree.InitialTreeView = InitialTreeView.NoExpand;
EndProcedure

&AtServer
Procedure FillInWithCategoriesServer()
	ReFillCategories();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CategoryTable.ProductCategory,
	|	CategoryTable.Brand,
	|	CategoryTable.Quota,
	|	CategoryTable.VariancePercentage
	|INTO TTDocumentCategories
	|FROM
	|	&CategoryTable AS CategoryTable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProductCategories.Owner AS ProductKind,
	|	ItemKinds.Description AS NameOfAdditionalTypeOfProduct,
	|	ItemKinds.Ref AS AdditionalTypeOfProducts
	|FROM
	|	Catalog.ProductCategories AS ProductCategories
	|		INNER JOIN Catalog.ItemKinds AS ItemKinds
	|		ON ProductCategories.Owner = ItemKinds.ProductCategoryOwner
	|ORDER BY
	|	ProductKind
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatalogCategories.Owner AS ProductKind,
	|	CatalogCategories.Owner.IsFolder AS ThisIsKindGroup,
	|	CatalogCategories.Owner.Description AS NameOfTypeOfProduct,
	|	CatalogCategories.Ref AS ProductCategory,
	|	CatalogCategories.Description AS CategoryName,
	|	CatalogCategories.IsFolder AS ThisIsCategoryGroup,
	|	ISNULL(DocumentCategories.Brand,VALUE(Catalog.Brands.EmptyRef)) AS Brand,
	|	ISNULL(DocumentCategories.Brand.Description,"""") AS BrandName,
	|	ISNULL(DocumentCategories.Quota, 0) AS Quota,
	|	ISNULL(DocumentCategories.VariancePercentage, 0) AS VariancePercentage
	|FROM
	|	Catalog.ProductCategories AS CatalogCategories
	|		LEFT JOIN TTDocumentCategories AS DocumentCategories
	|		ON CatalogCategories.Ref = DocumentCategories.ProductCategory
	|WHERE
	|	NOT CatalogCategories.IsFolder
	|	AND NOT CatalogCategories.DeletionMark
	|
	|ORDER BY
	|	NameOfTypeOfProduct,
	|	CategoryName,
	|	BrandName
	|TOTALS
	|	SUM(Quota),
	|	0 AS VariancePercentage
	|BY
	|	ProductKind HIERARCHY,
	|	ProductCategory HIERARCHY";
	
	Query.SetParameter("CategoryTable",Object.ProductCategories.Unload());
	
	ResultsArray = Query.ExecuteBatch();
	
	AdditionalKinds = MatchingDifferentViewsBasedOnQueryResult(ResultsArray[ResultsArray.Count() - 2]);
	
	FillInTreeBasedOnQueryResult(ResultsArray[ResultsArray.Count() - 1], AdditionalKinds);
	
EndProcedure

&AtServer
Procedure UpdateTotalsServer()
	TreeObject = FormAttributeToValue("CategoryTree",Type("ValueTree"));
	TotalQuota = TreeObject.Rows.Total("Quota");
	If TotalQuota = RecommendedQuota Then
		Items.TotalQuota.TextColor = New Color(0,128,0);
		Items.RecommendedQuota.TextColor = New Color(0,128,0);
	Else
		Items.TotalQuota.TextColor = New Color(22,39,121);
		Items.RecommendedQuota.TextColor = New Color(22,39,121);
	EndIf;
	TreeObject = Undefined;
EndProcedure

&AtServer
Procedure UpdateRecommendedMetrics()
	
	If TypeOf(Object.PlanningObject) = Type("CatalogRef.StoreFormats") Then
	
		RecommendedQuota = Common.ObjectAttributeValue(Object.PlanningObject, "NumberOfItemsInProductRange");
	
	Else
	
		RecommendedQuota = 0;
	
	EndIf; 
	
EndProcedure

&AtServer
Procedure CreateTreeBasedOnCategoryTable()
	
	SourceTable1 = Object.ProductCategories.Unload();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CategoryTable.ProductCategory,
	|	CategoryTable.Brand,
	|	CategoryTable.Quota,
	|	CategoryTable.VariancePercentage
	|INTO TTDocumentCategories
	|FROM
	|	&SourceTable1 AS CategoryTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CAST(TTDocumentCategories.ProductCategory AS Catalog.ProductCategories).Owner AS ProductKind,
	|	ItemKinds.Description AS NameOfAdditionalTypeOfProduct,
	|	ItemKinds.Ref AS AdditionalTypeOfProducts
	|FROM
	|	TTDocumentCategories AS TTDocumentCategories
	|		INNER JOIN Catalog.ItemKinds AS ItemKinds
	|		ON TTDocumentCategories.ProductCategory.Owner = ItemKinds.ProductCategoryOwner
	|ORDER BY
	|	ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductCategories.ProductCategory.Owner AS ProductKind,
	|	ProductCategories.ProductCategory.Owner.IsFolder AS ThisIsKindGroup,
	|	ProductCategories.ProductCategory.Owner.Description AS NameOfTypeOfProduct,
	|	ProductCategories.ProductCategory AS ProductCategory,
	|	ProductCategories.ProductCategory.Description AS CategoryName,
	|	ProductCategories.ProductCategory.IsFolder AS ThisIsCategoryGroup,
	|	ProductCategories.Brand AS Brand,
	|	ProductCategories.Brand.Description AS BrandName,
	|	ProductCategories.Quota AS Quota,
	|	ProductCategories.VariancePercentage AS VariancePercentage
	|FROM
	|	TTDocumentCategories AS ProductCategories
	|WHERE
	|	NOT ProductCategories.ProductCategory.IsFolder
	|
	|ORDER BY
	|	NameOfTypeOfProduct,
	|	CategoryName,
	|	BrandName
	|TOTALS
	|	SUM(Quota),
	|	AVG(VariancePercentage)
	|BY
	|	ProductKind HIERARCHY,
	|	ProductCategory HIERARCHY";
	
	Query.SetParameter("SourceTable1",SourceTable1);
	
	ResultsArray = Query.ExecuteBatch();
	
	AdditionalKinds = MatchingDifferentViewsBasedOnQueryResult(ResultsArray[ResultsArray.Count() - 2]);
	
	//
	FillInTreeBasedOnQueryResult(ResultsArray[ResultsArray.Count() - 1], AdditionalKinds);
	
EndProcedure


// Returns the correspondence of additional item types
// 
// Parameters:
// 	QueryResult - QueryResult -
// Returns:
// 	FixedMap - 
//
&AtServer
Function MatchingDifferentViewsBasedOnQueryResult(QueryResult)
	SamplingByAdditionalSpecies = QueryResult.Select();
	
	If SamplingByAdditionalSpecies.Next() Then
		AdditionalTypesOfCompliance = New Map;
		
		CurrentKind = SamplingByAdditionalSpecies.ProductKind; 
		ArrayOfAdditionalViews = New Array;
		
		SamplingByAdditionalSpecies.Reset();
		While SamplingByAdditionalSpecies.Next() Do
			
			If SamplingByAdditionalSpecies.ProductKind <> CurrentKind Then
				
				AdditionalTypesOfCompliance.Insert(CurrentKind, New FixedArray(ArrayOfAdditionalViews));
				ArrayOfAdditionalViews = New Array;
				
			EndIf;
			
			DescriptionOfAppearance = New Structure;
			DescriptionOfAppearance.Insert("Ref",SamplingByAdditionalSpecies.AdditionalTypeOfProducts); 
			DescriptionOfAppearance.Insert("Description",SamplingByAdditionalSpecies.NameOfAdditionalTypeOfProduct); 
			
			ArrayOfAdditionalViews.Add(New FixedStructure(DescriptionOfAppearance));
			
		EndDo;	
		AdditionalTypesOfCompliance.Insert(CurrentKind, New FixedArray(ArrayOfAdditionalViews));
		
		AdditionalKinds = New FixedMap(AdditionalTypesOfCompliance);
	Else
		AdditionalKinds = New FixedMap(New Map);
	EndIf;
	
	Return AdditionalKinds;
EndFunction

&AtServer
Procedure FillInTreeBasedOnQueryResult(QueryResult, AdditionalKinds)
	TreeObject = FormAttributeToValue("CategoryTree", Type("ValueTree"));
	TreeObject.Rows.Clear();
	//
	TreeResult = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	FillInSubordinateRows(TreeObject, TreeResult, AdditionalKinds);
	
	ValueToFormAttribute(TreeObject,"CategoryTree");
	Items.CategoryTree.InitialTreeView = InitialTreeView.NoExpand;
	
EndProcedure

&AtServer
Procedure FillInSubordinateRows(DestinationParent, SourceParent, AdditionalKinds)
	
	For Each SourceRow1 In SourceParent.Rows Do
		
		DestinationRow1 = DestinationParent.Rows.Add();
		FillPropertyValues(DestinationRow1,SourceRow1);
		If SourceRow1.Brand <> Null Then
			If ValueIsFilled(SourceRow1.Brand) Then
				DestinationRow1.TypeCategoryBrand = SourceRow1.Brand;
				DestinationRow1.Presentation = SourceRow1.BrandName;
			Else
				DestinationRow1.TypeCategoryBrand = Catalogs.Brands.EmptyRef();
				DestinationRow1.Presentation = NStr("vi = 'Nhãn hiệu khác';
													|ru = 'Прочие марки';
													|en = 'Other brands'; fa = 'Other brands';
													|it = 'Altri marchi';
													|pl = 'Inne marki';
													|tr = 'Diğer markalar'");
			EndIf;
			
			DestinationRow1.ThisIsTotal = False;
			DestinationRow1.PictureIndex = 2;
		ElsIf SourceRow1.ProductCategory <> Null Then
			DestinationRow1.TypeCategoryBrand = SourceRow1.ProductCategory;
			DestinationRow1.Presentation = SourceRow1.CategoryName;
			DestinationRow1.ThisIsTotal = True;
			If SourceRow1.ThisIsCategoryGroup Then
				DestinationRow1.PictureIndex = 0;
			Else
				DestinationRow1.PictureIndex = 1;
			EndIf;
		Else
			TextOfAdditionalViews = "";
			TypeText = NStr("vi = '%MainView%';
							|ru = '%MainView%';
							|en = '%MainView%'; fa = '%MainView%';
							|it = '%MainView%';
							|pl = '%MainView%';
							|tr = '%MainView%'");
			
			If Not SourceRow1.ThisIsKindGroup Then 
				AdditionalSpeciesFound = AdditionalKinds.Get(SourceRow1.ProductKind); // Array of CatalogRef.ItemKinds
				
				If AdditionalSpeciesFound <> Undefined Then
					TypeText = NStr("vi = '%MainView% (cũng như %AdditionalKinds%)';
									|ru = '%MainView% (а так же %AdditionalKinds%)';
									|en = '%MainView% (as well as %AdditionalKinds%)'; fa = '%MainView% (as well as %AdditionalKinds%)';
									|it = '%MainView% (e anche %AdditionalKinds%)';
									|pl = '%MainView% (a tаk że %AdditionalKinds%)';
									|tr = '%MainView% (aynı zamanda %AdditionalKinds%)'");
					
					For Each AdditionalView In AdditionalSpeciesFound Do
						TextOfAdditionalViews = TextOfAdditionalViews + AdditionalView.Description + ", ";	
					EndDo;
					
					TextOfAdditionalViews = Left(TextOfAdditionalViews, StrLen(TextOfAdditionalViews) - 2);
				EndIf;
				
			EndIf;
			DestinationRow1.TypeCategoryBrand = SourceRow1.ProductKind;
			
			DestinationRow1.Presentation = TypeText;
			DestinationRow1.Presentation = StrReplace(DestinationRow1.Presentation, "%MainView%", SourceRow1.NameOfTypeOfProduct);
			DestinationRow1.Presentation = StrReplace(DestinationRow1.Presentation, "%AdditionalKinds%", TextOfAdditionalViews);
			
			DestinationRow1.ThisIsTotal = True;
			DestinationRow1.PictureIndex = 0;
		EndIf;
		
		// And recursively subordinate
		FillInSubordinateRows(DestinationRow1,SourceRow1, AdditionalKinds);
	EndDo;

EndProcedure

&AtServer
Procedure ReFillCategories(CurrentObject = Undefined)
	If CurrentObject = Undefined Then
		Object.ProductCategories.Clear();
		HandleSubordinateRowsWhenOverfilling(CategoryTree);
	Else
		CurrentObject.ProductCategories.Clear();
		HandleSubordinateRowsWhenOverfilling(CategoryTree, CurrentObject);
	EndIf;
EndProcedure

&AtServer
Procedure HandleSubordinateRowsWhenOverfilling(ParentTreeElement, CurrentObject = Undefined)
	TreeItems = ParentTreeElement.GetItems();
	For Each TreeItem In TreeItems Do
		If TreeItem.ThisIsTotal Then
			HandleSubordinateRowsWhenOverfilling(TreeItem, CurrentObject);
		Else
			AddRowToCategoryTableWhenRefilling(TreeItem, CurrentObject);
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure AddRowToCategoryTableWhenRefilling(TreeItem, CurrentObject = Undefined)
	Parent = TreeItem.GetParent();
	If Parent<>Undefined Then
		CurCategory = Parent.TypeCategoryBrand;
		If CurrentObject = Undefined Then
			NewRow = Object.ProductCategories.Add();
		Else
			NewRow = CurrentObject.ProductCategories.Add();
		EndIf;
		NewRow.ProductCategory = CurCategory;
		//
		NewRow.Brand				 =  TreeItem.TypeCategoryBrand;
		NewRow.Quota				 =  TreeItem.Quota;
		NewRow.VariancePercentage	 =  TreeItem.VariancePercentage;
	EndIf;
EndProcedure

&AtServer
Procedure CategoryTreeAfterDeleteRowServer()
	ReFillCategories();
	UpdateTotalsServer();
EndProcedure

&AtServer
Function HavingPlanServer()
	Return Documents.SetProductRangeQuotas.ThereIsPlan_(Object.PlanningObject, Object.ValidityStartDate, Object.Ref);
EndFunction

&AtServer
Function BrandHasAlreadyBeenAdded(ParentLevelRow, SelectedBrand)
	AlreadyAdded_ = False;
	SubordinateRows = CategoryTree.FindByID(ParentLevelRow).GetItems();
	For Each SubordinateRow In SubordinateRows Do
		If SubordinateRow.TypeCategoryBrand = SelectedBrand Then
			AlreadyAdded_ = True;
			Break;
		EndIf;
	EndDo;
	Return AlreadyAdded_;
EndFunction

&AtServerNoContext
Function CollectionOfProductsWhenChangedOnServer(ItemsCollection)
	
	Return Common.ObjectAttributeValue(ItemsCollection, "PurchaseStartDate");
	
EndFunction

&AtClient
Procedure UploadQuotasFromAFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then 
		Return;
	EndIf;
	
	LoadQuotasFromFileOnServer(ImportedDataAddress);
	
EndProcedure

&AtServer
Procedure LoadQuotasFromFileOnServer(ImportedDataAddress)
	
	ReFillCategories();
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	LinesAdded = False;
	For Each TableRow In ImportedData Do 
		
		NewRow = Object.ProductCategories.Add();
		FillPropertyValues(NewRow, TableRow);
		LinesAdded = True;

	EndDo;
	
	If LinesAdded Then
		Modified = True;
		
		CreateTreeBasedOnCategoryTable();
		
		UpdateTotalsServer();
		UpdateRecommendedMetrics();
	EndIf;
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_ValidityStartDate" Then
		ValidityStartDateOnChange(Items.ValidityStartDate);
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
