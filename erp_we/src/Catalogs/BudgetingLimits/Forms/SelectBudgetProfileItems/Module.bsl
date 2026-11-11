#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("Owner", BudgetingModel) Then
		MessageText = NStr("vi = 'Mở trực tiếp của hình thức này không được cung cấp. Để mở biểu mẫu, bạn có thể sử dụng lệnh ""Thêm theo loại ngân sách"" dưới dạng danh sách các quy tắc giới hạn theo dữ liệu ngân sách.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено. Для открытия формы можно воспользоваться командой ""Добавить по виду бюджета"" в форме списка правил лимитов по данным бюджетирования.';
							|en = 'Application cannot open this form explicitly. It opens implicitly when you select the ""Add by budget profile"" command in the ""Rules for budgeting limits"" form.'; fa = 'Application cannot open this form explicitly. It opens implicitly when you select the ""Add by budget profile"" command in the ""Rules for budgeting limits"" form.';
							|it = 'L''apertura diretta di questo modulo non è predisposta. Per aprire il modulo, è possibile utilizzare il comando ""Aggiungere per tipo di budget"" nel modulo dell''elenco di regole per i limiti in base ai dati di budgeting.';
							|pl = 'Bezpośrednie otwieranie tego formularza nie zostało przewidziane. W celu otwarcia formularza można użyć polecenia ""Добавить по виду бюджета"" w formularze listy reguł limitów danych budżetowania.';
							|tr = 'Bu formun doğrudan açılmasına izin verilmiyor. Formu açmak için bütçeleme verilerine göre kural limiti liste formundaki ""Bütçe profiline göre ekle"" komutundan faydalanabilirsiniz.'");
		Raise MessageText;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(TypesOfBudget, "Owner", BudgetingModel);
	CommonClientServer.SetDynamicListFilterItem(TypesOfBudget, "UseToEnterPlan", True);
	
EndProcedure

#EndRegion

#Region TableEventHandlersForms

&AtClient
Procedure TypesOfBudgetSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	Next(Undefined);
	
EndProcedure

&AtClient
Procedure BudgetProfileItemTreeSelectionCheckBoxOnChange(Item)
	
	CurrentData = Items.BudgetProfileItemTree.CurrentData;
	SetFlagRecursively(CurrentData.GetItems(), CurrentData.SelectionCheckBox);
	
	RowParent = FinancialReportingClientServer.RowParent(CurrentData);
	While RowParent <> Undefined Do
		SelectionCheckBox = False;
		SubordinateParentItems1 = RowParent.GetItems();
		For Each SubordinateItem In SubordinateParentItems1 Do
			SelectionCheckBox = SubordinateItem.SelectionCheckBox;
			If SelectionCheckBox Then
				Break;
			EndIf;
		EndDo;
		RowParent.SelectionCheckBox = SelectionCheckBox;
		RowParent = FinancialReportingClientServer.RowParent(RowParent);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	Items.FormNext.Title = NStr("vi = 'Tiếp theo';
								|ru = 'Далее';
								|en = 'Next'; fa = 'بعدی';
								|it = 'Avanti';
								|pl = 'Next';
								|tr = 'İleri'") + " >>>";
	If Items.GroupPages.CurrentPage.Name = "SelectBudgetProfile" Then
		CurrentData = Items.TypesOfBudget.CurrentData;
		If CurrentData = Undefined
			Or Not ValueIsFilled(CurrentData.Ref) Then
			WarningText = NStr("vi = 'Loại ngân sách không được chọn';
								|ru = 'Не выбран вид бюджета';
								|en = 'Budget profile is not selected'; fa = 'Budget profile is not selected';
								|it = 'Nessun tipo di bilancio selezionato';
								|pl = 'Nie wybrano rodzaju budżetu';
								|tr = 'Bütçe profili seçilmemiş'");
			ShowMessageBox(,WarningText);
			Return;
		EndIf;
		If CurrentData.IsFolder Then
			WarningText = NStr("vi = 'Bạn không thể tạo giới hạn cho một nhóm các loại ngân sách. Chọn một loại ngân sách.';
								|ru = 'Создать лимиты по группе видов бюджета нельзя. Выберите вид бюджета.';
								|en = 'Cannot create limits by the budget profile group. Select a budget profile.'; fa = 'Cannot create limits by the budget profile group. Select a budget profile.';
								|it = 'Non è possibile creare limiti per un gruppo di tipi di bilancio. Selezionare un tipo di bilancio.';
								|pl = 'Tworzenie limitów wg grupy rodzajów budżetów nie jest możliwe. Wybierz rodzaj budżetu.';
								|tr = 'Bütçe profili grubuna göre limit oluşturulamaz. Bütçe profili seçiniz.'");
			ShowMessageBox(,WarningText);
			Return;
		EndIf;
		BudgetProfile = CurrentData.Ref;
		FillInTreeOfElementsAvailableForCreation();
		Items.GroupPages.CurrentPage = Items.SelectBudgetProfileItems;
		For Each TreeRow In BudgetProfileItemTree.GetItems() Do
			Items.BudgetProfileItemTree.Expand(TreeRow.GetID(), True);
		EndDo;
	ElsIf Items.GroupPages.CurrentPage.Name = "SelectBudgetProfileItems" Then
		RulesCreated = RulesAreCreatedOnServer();
		If RulesCreated Then
			Items.GroupPages.CurrentPage = Items.SelectItemsCreated;
		Else
			Items.GroupPages.CurrentPage = Items.SelectItemsError;
		EndIf;
		Items.FormNext.Title = NStr("vi = 'Đồng ý';
									|ru = 'Готово';
									|en = 'Done'; fa = 'انجام شد';
									|it = 'Done';
									|pl = 'Done';
									|tr = 'Bitir'");
	ElsIf Items.GroupPages.CurrentPage.Name = "SelectItemsCreated"
		Or Items.GroupPages.CurrentPage.Name = "SelectItemsError" Then
		Close(True);
	EndIf;
	
	Items.FormBack.Enabled = Items.GroupPages.CurrentPage <> Items.SelectBudgetProfile
			And Items.GroupPages.CurrentPage <> Items.SelectItemsCreated
			And Items.GroupPages.CurrentPage <> Items.SelectItemsError;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If Items.GroupPages.CurrentPage.Name = "SelectBudgetProfileItems" Then
		Items.GroupPages.CurrentPage = Items.SelectBudgetProfile;
	EndIf;
	
	Items.FormBack.Enabled = Items.GroupPages.CurrentPage <> Items.SelectBudgetProfile
			And Items.GroupPages.CurrentPage <> Items.SelectItemsCreated
			And Items.GroupPages.CurrentPage <> Items.SelectItemsError;
	
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	
	SetFlagRecursively(BudgetProfileItemTree.GetItems(), False);
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	SetFlagRecursively(BudgetProfileItemTree.GetItems(), True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetFlagRecursively(TreeRows, SelectionCheckBox)
	
	For Each TreeRow In TreeRows Do
		TreeRow.SelectionCheckBox = SelectionCheckBox;
		SetFlagRecursively(TreeRow.GetItems(), SelectionCheckBox);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInTreeOfElementsAvailableForCreation()
	
	AttributeCache = FinancialReportingServer.CacheAdditionalDetails(BudgetProfile);
	
	BudgetItemTree = BudgetReportingCacheCalculationServer.BudgetItemTree(BudgetProfile, True);
	SettingsTable = BudgetReportingCacheCalculationServer.ElementsForConfiguringBudgetViewCells(BudgetProfile);
	
	// The hierarchy of analytics and dimensions is defined as follows.
	// 	Dimensions are located at the beginning of the hierarchy if accounting for them is set in the budgeting model.
	// 	Then there are analysts in the header of the budget view.
	// 	Then the analysts located in columns (and if the table is simple, but the indicator is in columns, then 
	// 	the analysts located in rows).
	// 	Then the analysts arranged in rows.
	
	// In a simple table, you can create a setting when different types of analytics are located below it for one article that are not nested in each other.
	// We will give the user the right to choose the appropriate settings.
		
	LinesOfArticles = BudgetItemTree.Rows.FindRows(New Structure("ItemKind", Enums.FinancialReportItemKinds.BudgetFlowItem), True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BudgetFlowItemDimensions.Ref AS Ref,
	|	BudgetFlowItemDimensions.Description AS Description
	|FROM
	|	ChartOfCharacteristicTypes.BudgetFlowItemDimensions AS BudgetFlowItemDimensions";
	
	CacheNamesAnalyst = New Map;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CacheNamesAnalyst.Insert(Selection.Ref, Selection.Description);
	EndDo;
	
	HeaderDimensions = Common.ObjectAttributeValue(BudgetProfile, "HeaderDimensions").Unload().UnloadColumn("DimensionKind");
	
	TableOfBudgetItems = New ValueTable;
	TableOfBudgetItems.Columns.Add("RootItem");
	TableOfBudgetItems.Columns.Add("BudgetFlowItem");
	TableOfBudgetItems.Columns.Add("AnalystNames");
	TableOfBudgetItems.Columns.Add("AnalystKeys");
	
	TableColumnCache = New Map;
	FiniteElementCacheAnalyst = New Map;
	ArraysOfAnalyticsByKey = New Map;
	
	For Each BudgetLineItem In LinesOfArticles Do
		
		Parent = BudgetLineItem.Parent;
		If ValueIsFilled(Parent) Then
			If Parent.ItemKind = Enums.FinancialReportItemKinds.DerivedItem
				Or Parent.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
				// Operands are not used to fill in the articles of limits and derived indicators.
				Continue;
			EndIf;
		EndIf;
		
		RootItem = FinancialReportingServer.RootItem(BudgetLineItem,
			Enums.FinancialReportItemKinds.TableIndicatorsInRows);
		If RootItem = Undefined Then
			RootItem = FinancialReportingServer.RootItem(BudgetLineItem,
				Enums.FinancialReportItemKinds.TableIndicatorsInColumns);
		EndIf;
		If RootItem = Undefined Then
			RootItem = FinancialReportingServer.RootItem(BudgetLineItem,
				Enums.FinancialReportItemKinds.ComplexTable);
		EndIf;
		
		OutputOfRootElementHeader = Undefined;
		If Not RootItem = Undefined Then
			OutputOfRootElementHeader = FinancialReportingServerCall.ValueOfAdditionalProps(RootItem.ReportItem, "DisplayItemTitle");
		EndIf;
		
		TableComplex_ = False;
		FinalStringElements = New Array;
		FinalColumnElements = New Array;
		If RootItem = Undefined Then
			// There is no table, only rows
			AddEndElementsToArray(FinalStringElements, BudgetLineItem);
		ElsIf RootItem.ItemKind = Enums.FinancialReportItemKinds.ComplexTable Then
			TableComplex_ = True;
			IntersectionOfRowsAndColumns = SettingsTable.Find(BudgetLineItem.ReportItem, "Item");
			If Not IntersectionOfRowsAndColumns = Undefined Then
				FinalStringElements.Add(IntersectionOfRowsAndColumns.String);
				FinalColumnElements.Add(IntersectionOfRowsAndColumns.Column);
			EndIf;
		ElsIf RootItem.ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInRows
			Or RootItem.ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInColumns Then
			AddEndElementsToArray(FinalStringElements, BudgetLineItem);
			
			TableColumns1 = Undefined;
			If RootItem.ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInRows Then
				TableColumns1 = RootItem.Rows.Find(Enums.FinancialReportItemKinds.Columns, "ItemKind");
			ElsIf RootItem.ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInColumns Then
				TableColumns1 = RootItem.Rows.Find(Enums.FinancialReportItemKinds.Rows, "ItemKind");
			EndIf;
			If Not TableColumns1 = Undefined Then
				If TableColumnCache.Get(RootItem) = Undefined Then
					AddEndElementsToArray(FinalColumnElements, TableColumns1);
					TableColumnCache.Insert(RootItem, FinalColumnElements);
				Else
					FinalColumnElements = TableColumnCache.Get(RootItem);
				EndIf;
			EndIf;
		EndIf;
		
		BudgetFlowItem = FinancialReportingServer.ValueOfAdditionalProps(BudgetLineItem.ReportItem, "BudgetFlowItem", AttributeCache);
		
		For Each FinalElementOfString In FinalStringElements Do
			
			// There may be no finite elements of columns (for an article without a table), so we first bypass the rows.
			HigherLevelRowElementAnalysts = FiniteElementCacheAnalyst.Get(FinalElementOfString);
			If HigherLevelRowElementAnalysts = Undefined Then
				HigherLevelRowElementAnalysts = New Array;
				FillOutHigherLevelAnalysts(FinalElementOfString, HigherLevelRowElementAnalysts, TableComplex_, AttributeCache);
				FiniteElementCacheAnalyst.Insert(FinalElementOfString, HigherLevelRowElementAnalysts);
			EndIf;
			
			If FinalColumnElements.Count() > 0 Then
				For Each FinalColumnElement In FinalColumnElements Do
					
					HigherLevelColumnElementAnalysts = FiniteElementCacheAnalyst.Get(FinalColumnElement);
					If HigherLevelColumnElementAnalysts = Undefined Then
						HigherLevelColumnElementAnalysts = New Array;
						FillOutHigherLevelAnalysts(FinalColumnElement, HigherLevelColumnElementAnalysts, TableComplex_, AttributeCache);
						FiniteElementCacheAnalyst.Insert(FinalColumnElement, HigherLevelColumnElementAnalysts);
					EndIf;
					
					AllAnalyticsArticles = CommonClientServer.CollapseArray(HeaderDimensions);
					For Each DimensionKind In HigherLevelColumnElementAnalysts Do
						AllAnalyticsArticles.Add(DimensionKind);
					EndDo;
					For Each DimensionKind In HigherLevelRowElementAnalysts Do
						AllAnalyticsArticles.Add(DimensionKind);
					EndDo;
					
					AnalystKeys = New Array;
					AnalystNames = New Array;
					For Each DimensionKind In AllAnalyticsArticles Do
						DimensionKey = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
						NameOfAnalytics  = CacheNamesAnalyst.Get(DimensionKind);
						
						AnalystKeys.Add(DimensionKey);
						AnalystNames.Add(NameOfAnalytics);
					EndDo; 
					AnalystKeys = StrConcat(AnalystKeys, ", ");
					AnalystNames = StrConcat(AnalystNames, ", ");
					
					ArraysOfAnalyticsByKey.Insert(AnalystKeys, AllAnalyticsArticles);
					
					NewRow = TableOfBudgetItems.Add();
					NewRow.RootItem = ?(OutputOfRootElementHeader = True, RootItem, Undefined);
					NewRow.BudgetFlowItem  = BudgetFlowItem;
					NewRow.AnalystNames = AnalystNames;
					NewRow.AnalystKeys = AnalystKeys;
					
				EndDo;
			Else
				
				AllAnalyticsArticles = CommonClientServer.CollapseArray(HeaderDimensions);
				For Each DimensionKind In HigherLevelRowElementAnalysts Do
					AllAnalyticsArticles.Add(DimensionKind);
				EndDo;
				
				AnalystKeys = New Array;
				AnalystNames = New Array;
				For Each DimensionKind In AllAnalyticsArticles Do
					DimensionKey = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
					NameOfAnalytics  = CacheNamesAnalyst.Get(DimensionKind);
					
					AnalystKeys.Add(DimensionKey);
					AnalystNames.Add(NameOfAnalytics);
				EndDo; 
				AnalystKeys = StrConcat(AnalystKeys, ", ");
				AnalystNames = StrConcat(AnalystNames, ", ");
				
				ArraysOfAnalyticsByKey.Insert(AnalystKeys, AllAnalyticsArticles);
				
				NewRow = TableOfBudgetItems.Add();
				NewRow.RootItem = ?(OutputOfRootElementHeader = True, RootItem, Undefined);
				NewRow.BudgetFlowItem = BudgetFlowItem;
				NewRow.AnalystNames = AnalystNames;
				NewRow.AnalystKeys = AnalystKeys;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	TableOfBudgetItems.GroupBy("RootItem, BudgetFlowItem, AnalystNames, AnalystKeys");
	TableOfBudgetItems.Sort("RootItem, BudgetFlowItem, AnalystNames");
	RootItems = TableOfBudgetItems.Copy(,"RootItem");
	RootItems.GroupBy("RootItem");
	RootItems = RootItems.UnloadColumn("RootItem");
	
	BudgetFlowItems = CommonClientServer.CollapseArray(TableOfBudgetItems.UnloadColumn("BudgetFlowItem"));
	DataOfBudgetItems = Common.ObjectsAttributesValues(BudgetFlowItems, "LimitedTransaction, Description");
	
	StorageAddressesForAnalyticsTypes = New Map;
	
	For Each RootItem In RootItems Do
		
		If RootItem = Undefined Then
			ArticleOutputElement = BudgetProfileItemTree.GetItems();
		Else
			TreeTableRow = BudgetProfileItemTree.GetItems().Add();
			TreeTableRow.NameForPrinting = RootItem.NameForPrinting;
			TreeTableRow.CustomPicture = FinancialReportingCached.CustomPicture(RootItem.ItemKind, "");
			
			ArticleOutputElement = TreeTableRow.GetItems();
		EndIf;
		
		ArticleAnalystCombinations = TableOfBudgetItems.FindRows(New Structure("RootItem", RootItem));
		For Each AnalystCombination In ArticleAnalystCombinations Do
			TheseBudgetItems = DataOfBudgetItems.Get(AnalystCombination.BudgetFlowItem);
			If Not ValueIsFilled(TheseBudgetItems.LimitedTransaction) Then
				Continue;
			EndIf;
			TreeRow = ArticleOutputElement.Add();
			TreeRow.BudgetFlowItem = AnalystCombination.BudgetFlowItem;
			TreeRow.LimitedTransaction = TheseBudgetItems.LimitedTransaction;
			TreeRow.NameForPrinting = TheseBudgetItems.Description;
			TreeRow.CustomPicture= FinancialReportingCached.CustomPicture(
				Enums.FinancialReportItemKinds.BudgetFlowItem, "");
			TreeRow.Dimensions = AnalystCombination.AnalystNames;
			
			StorageAddress = StorageAddressesForAnalyticsTypes.Get(AnalystCombination.AnalystKeys);
			If StorageAddress = Undefined Then
				DimensionKinds = ArraysOfAnalyticsByKey.Get(AnalystCombination.AnalystKeys);
				StorageAddress = PutToTempStorage(DimensionKinds, UUID);
				StorageAddressesForAnalyticsTypes.Insert(AnalystCombination.AnalystKeys, StorageAddress);
			EndIf;
			TreeRow.AddressOfDimensionArray = StorageAddress;
			
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure AddEndElementsToArray(ArrayOfFiniteElements, Var_CurrentItem)
	
	If Var_CurrentItem.Rows.Count() = 0 Then
		ArrayOfFiniteElements.Add(Var_CurrentItem);
	Else
		For Each String In Var_CurrentItem.Rows Do
			AddEndElementsToArray(ArrayOfFiniteElements, String);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillOutHigherLevelAnalysts(Val TreeItem, ListOfAnalysts, TableComplex_, AttributeCache)
	
	If TreeItem = Undefined Then
		Return;
	EndIf;
	If TreeItem.ItemKind = Enums.FinancialReportItemKinds.Rows
		Or TreeItem.ItemKind = Enums.FinancialReportItemKinds.Columns Then
		Return;
	EndIf;
	If TreeItem.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
		If TableComplex_ Then
			ReportItem = TreeItem.Ref;
		Else
			ReportItem = TreeItem.ReportItem;
		EndIf;
		DimensionType = FinancialReportingServer.ValueOfAdditionalProps(ReportItem,
			ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.DimensionType,
			AttributeCache);
			
		If DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension
			Or DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
			
			DimensionKind = FinancialReportingServer.ValueOfAdditionalProps(ReportItem,
				ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.DimensionKind,
				AttributeCache);
			
			ListOfAnalysts.Insert(0, DimensionKind);
		EndIf;
	EndIf;
	
	FillOutHigherLevelAnalysts(TreeItem.Parent, ListOfAnalysts, TableComplex_, AttributeCache)
	
EndProcedure

&AtServer
Procedure HowToCreateTreeElements(ItemsTree, RootItem, CreatedOn)
	
	For Each String In ItemsTree.Rows Do
		
		If Not String.SelectionCheckBox Then
			Continue;
		EndIf;
		
		If ValueIsFilled(String.BudgetFlowItem) Then
			
			NewItem = Catalogs.BudgetingLimits.CreateItem();
			NewItem.Description = String(String.BudgetFlowItem);
			NewItem.BudgetFlowOrBalanceItem = String.BudgetFlowItem;
			NewItem.LimitedTransaction = String.LimitedTransaction;
			NewItem.Periodicity = Common.ObjectAttributeValue(BudgetProfile, "Periodicity");
			NewItem.LimitType = Enums.TypesOfCashExpenseLimit.AllowingWithinLimit;
			
			BudgetingModelData = Common.ObjectAttributesValues(BudgetingModel,
				"BudgetsByCompanies, BudgetsByBusinessUnits");
			If BudgetingModelData.BudgetsByCompanies Then
				NewRow = NewItem.DimensionsHierarchy.Add();
				NewRow.DimensionName = "Organization";
				NewRow.Used = True;
			EndIf;
			
			If BudgetingModelData.BudgetsByBusinessUnits Then
				NewRow = NewItem.DimensionsHierarchy.Add();
				NewRow.DimensionName = "Department";
				NewRow.Used = True;
			EndIf;
			
			DimensionKinds = GetFromTempStorage(String.AddressOfDimensionArray);
			For Each DimensionKind In DimensionKinds Do
				NewRow = NewItem.DimensionsHierarchy.Add();
				NewRow.DimensionKind = DimensionKind;
				NewRow.Used = True;
			EndDo;
			
			NewItem.Owner = BudgetingModel;
			NewItem.Parent = RootItem;
			NewItem.Write();
			CreatedOn = CreatedOn + 1;
			
		Else 
			
			Var_Group = Catalogs.BudgetingLimits.CreateFolder();
			Var_Group.Description = String.NameForPrinting;
			Var_Group.Owner = BudgetingModel;
			Var_Group.Parent = RootItem;
			Var_Group.Write();
			
			HowToCreateTreeElements(String, Var_Group.Ref, CreatedOn);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function RulesAreCreatedOnServer()
	RulesCreated = True;
	DefaultLanguageCode   = Common.DefaultLanguageCode();
	ErrorPresentation = "";
	ItemsTree = FormAttributeToValue("BudgetProfileItemTree");
	FoundRows = ItemsTree.Rows.FindRows(New Structure("SelectionCheckBox", True), True);
	If FoundRows.Count() Then
		
		BeginTransaction();
		Try
			CreatedOn = 0;
			RootItem = Catalogs.BudgetingLimits.CreateFolder();
			RootItem.Description = String(BudgetProfile);
			RootItem.Owner = BudgetingModel;
			RootItem.Write();
			HowToCreateTreeElements(ItemsTree, RootItem.Ref, CreatedOn);
			RulesCreated = True;
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorText = NStr("vi = 'Không thể tạo quy tắc giới hạn cho loại ngân sách:%1 mô hình ngân sách:%2, do:%3';
							|ru = 'Не удалось создать правила лимитов для вида бюджета: %1 модели бюджетирования: %2, по причине: %3';
							|en = 'Cannot create limits for the budget profile %1 of the budgeting model %2. Reason: %3'; fa = 'Cannot create limits for the budget profile %1 of the budgeting model %2. Reason: %3';
							|it = 'Impossibile creare regole per i limiti per tipo di bilancio: %1 del modello di budgeting:%2, a causa di: %3';
							|pl = 'Tworzenie reguł limitów dla rodzaju budżetu: %1 modelu budżetowania: %2 nie powiodło się z powodu: %3';
							|tr = 'Bütçe profili için kural limiti oluşturulamadı: %1 bütçelendirme modeli: %2, şu sebepten dolayı: %3'",
				DefaultLanguageCode);
			ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
					String(BudgetProfile),
					String(BudgetingModel),
					ErrorPresentation);
			LREvent = NStr("vi = 'Quy tắc giới hạn ngân sách';
							|ru = 'Правила лимитов по данным бюджетирования';
							|en = 'Rules for budgeting limits'; fa = 'قواعد سقف‌های بودجه‌بندی';
							|it = 'Regole di limitazioni per dati di budgeting';
							|pl = 'Reguły limitów dla danych budżetowych';
							|tr = 'Bütçe limiti'", DefaultLanguageCode)
				+ "." + NStr("vi = 'Tạo quy tắc';
							|ru = 'Создание правил';
							|en = 'Create rules'; fa = 'Create rules';
							|it = 'Creazione regole';
							|pl = 'Utworzenie reguł';
							|tr = 'Kural oluşturma'", DefaultLanguageCode);
			WriteLogEvent(LREvent,
				EventLogLevel.Error,,,
				ErrorText);
			
			RulesCreated = False;
		EndTry;
		If RulesCreated Then
			TitleDecorations = NStr("vi = 'Quy tắc được tạo thành công';
									|ru = 'Правила созданы успешно';
									|en = 'Rules are created successfully'; fa = 'Rules are created successfully';
									|it = 'Regole generate con successo';
									|pl = 'Reguły zostały utworzone pomyślnie';
									|tr = 'Kurallar başarıyla oluşturuldu'")
					+ Chars.LF + NStr("vi = 'Quy tắc hạn mức được tạo: %1';
										|ru = 'Создано правил лимитов: %1';
										|en = 'Created limit rules: %1'; fa = 'Created limit rules: %1';
										|it = 'Regole di limiti create: %1';
										|pl = 'Utworzono reguł limitów: %1';
										|tr = 'Oluşturulan limit kuralı: %1'");
			Items.DecorationCreated.Title = StringFunctionsClientServer.SubstituteParametersToString(TitleDecorations,
				CreatedOn);
		Else
			TitleDecorations = NStr("vi = 'Không thể tạo quy tắc do:';
									|ru = 'Не удалось создать правила по причине:';
									|en = 'Cannot create rules. Reason:'; fa = 'Cannot create rules. Reason:';
									|it = 'Impossibile creare regole a causa di:';
									|pl = 'Tworzenie reguł nie powiodło się z powodu:';
									|tr = 'Kural şu sebeple oluşturulamadı:'")
					+ Chars.LF + "%1";
			Items.ErrorDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(TitleDecorations,
				ErrorPresentation);
		EndIf;
	Else
		TitleDecorations = NStr("vi = 'Chưa chọn dạng ngân sách để tạo quy tắc.';
								|ru = 'Не выбраны статьи бюджетов для создания правил.';
								|en = 'Budget flow items for creating rules are not selected.'; fa = 'Budget flow items for creating rules are not selected.';
								|it = 'Budget flow items for creating rules are not selected.';
								|pl = 'Budget flow items for creating rules are not selected.';
								|tr = 'Kural oluşturmak için bütçe kalemleri seçilmedi.'")
			+ Chars.LF + NStr("vi = 'Chưa tạo quy tắc hạn chế.';
								|ru = 'Правила лимитов не были созданы.';
								|en = 'The limit rules are not created.'; fa = 'The limit rules are not created.';
								|it = 'The limit rules are not created.';
								|pl = 'The limit rules are not created.';
								|tr = 'Limit kuralları oluşturulmadı.'");
		Items.DecorationCreated.Title = TitleDecorations;
	EndIf;
	
	Return RulesCreated;
	
EndFunction

#EndRegion

