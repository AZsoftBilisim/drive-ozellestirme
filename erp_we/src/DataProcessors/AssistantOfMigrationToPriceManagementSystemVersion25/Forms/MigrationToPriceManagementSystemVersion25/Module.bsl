
#Region Variables

&AtClient
Var CloseOfCourse;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UpdatingTransitionStatusOnServer();
		
	If State <> Enums.JobsStates.Running Then
		
		DateOfMigrationToPriceManagementSystem25 = PriceManagementSystemServerCall.DateOfTransitionToPricingVersion25();
		If Not ValueIsFilled(DateOfMigrationToPriceManagementSystem25) Then
			DateOfMigrationToPriceManagementSystem25 = BegOfDay(CurrentSessionDate() + 86400);
		EndIf;
		
	EndIf;
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemsBatch          = GetFunctionalOption("UseItemsBatch");
	UseItemPackages       = GetFunctionalOption("UseItemPackages");
	
	CustomizeForm();
	
	SetConditionalAppearance();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenForm();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Or ValueIsFilled(StartDate) Or CloseOfCourse = True Then
		Return;
	EndIf;
	
	Cancel = True;
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("BeforeClosingAlert", ThisObject);
	QueryText = NStr("vi = 'Đóng trợ giúp?';
					|ru = 'Закрыть помощник?';
					|en = 'Close the wizard?'; fa = 'Close the wizard?';
					|it = 'Chiudere assistente?';
					|pl = 'Zamknij asystenta?';
					|tr = 'Sihirbaz kapatılsın mı?'");
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)

	If Items.Pages.CurrentPage = Items.StartPage_ Then
		NewPage = PageStartNext();
	ElsIf Items.Pages.CurrentPage = Items.PageForSelectingPriceTypes Then
		NewPage = PageForSelectingTypesOfPricesNext();
	ElsIf Items.Pages.CurrentPage = Items.PageForConfiguringItemTypes Then
		NewPage = ProductTypesSettingsPageNext();
	ElsIf Items.Pages.CurrentPage = Items.ThePageForStartingTheAutomaticTransition Then
		NewPage = PageForStartingAutomaticNavigationNext();
	ElsIf Items.Pages.CurrentPage = Items.PageWait Then
		NewPage = WaitingPageNext();
	ElsIf Items.Pages.CurrentPage = Items.ResultPage Then
		NewPage = PageResultNext();
	ElsIf Items.Pages.CurrentPage = Items.ErrorPage Then
		NewPage = ErrorPageNext();
	EndIf;
	
	If NewPage <> Undefined Then
		OpeningPage(NewPage);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If Items.Pages.CurrentPage = Items.PageForSelectingPriceTypes Then
		Page = Items.StartPage_;
	ElsIf Items.Pages.CurrentPage = Items.PageForConfiguringItemTypes Then
		Page = Items.PageForSelectingPriceTypes;
	ElsIf Items.Pages.CurrentPage = Items.ThePageForStartingTheAutomaticTransition Then
		Page = Items.PageForConfiguringItemTypes;
	EndIf;
	
	If Page <> Undefined Then
		OpeningPage(Page, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure DisplayOnlySelectedItems(Command)
	
	TheTreeSelectedPricesDisplayOnlySelectedItems = Not TheTreeSelectedPricesDisplayOnlySelectedItems;
	FillInTreeOfPriceTypes();	
	
EndProcedure

&AtClient
Procedure SelectAllPriceTypes(Command)
	ChangeSelectedFlagInPriceViewTreeServer(True);
EndProcedure

&AtClient
Procedure ClearAllPriceTypes(Command)
	ChangeSelectedFlagInPriceViewTreeServer(False);
EndProcedure

&AtServer
Procedure ChangeSelectedFlagInPriceViewTreeServer(FlagSelected)
	
	Tree = FormAttributeToValue("TheTreeSelectedPrices", Type("ValueTree"));	
	ChangeSelectedFlagInPriceViewTree(Tree.Rows, FlagSelected);
	ValueToFormData(Tree, TheTreeSelectedPrices);
	
EndProcedure

&AtClient
Procedure TheTreeSelectedPricesRefClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure TheTreeSelectedPricesRefStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure TheTreeSelectedPricesSelection(Item, RowSelected, Field, StandardProcessing)
		
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	
	If CurrentData <> Undefined Then
		If Not CurrentData.IsFolder Then
			If Field = Items.TheTreeSelectedPricesInfluencingPrices Then
				If CurrentData.InfluencingPrices.Count() > 0 Then
					ShowValue(Undefined, CurrentData.InfluencingPrices);
				EndIf;
			ElsIf Field = Items.TheTreeSelectedPricesDependentPrices Then	
					If CurrentData.DependentPrices.Count() > 0 Then
						ShowValue(Undefined, CurrentData.DependentPrices);
					EndIf;
			Else
				ShowValue(Undefined, CurrentData.Ref);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TheTreeSelectedPricesBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure


&AtClient
Procedure TheTreeSelectedPricesValueChoice(Item, Value, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region Private

#Region PageHandlers

&AtClient
Procedure OpeningPage(Page, ItSBackwardsTransition = False)
	
	Items.Next.Visible = True;
	Items.Next.Enabled = True;
	Items.Next.Title = NStr("vi = 'Tiếp theo >>';
							|ru = 'Далее >>';
							|en = 'Next >>'; fa = 'بعدی >>';
							|it = 'Avanti >>';
							|pl = 'Dalej >>';
							|tr = 'İleri >>'");
	
	Items.Cancel.Visible = False;
	Items.Cancel.Title = NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Annulla';
								|pl = 'Anuluj';
								|tr = 'İptal'");
	
	ChangeSuggestion("Next", NStr("vi = 'Tiếp theo';
									|ru = 'Далее';
									|en = 'Next'; fa = 'بعدی';
									|it = 'Avanti';
									|pl = 'Dalej';
									|tr = 'İleri'"));
	ChangeSuggestion("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Anuluj';
									|tr = 'İptal'"));
	
	Items.Back.Visible = True;
	
	If Page = Items.StartPage_ Then
		PageInitialOpening(ItSBackwardsTransition);
	ElsIf Page = Items.PageForSelectingPriceTypes Then
		PriceSelectionPageOpening(ItSBackwardsTransition);
	ElsIf Page = Items.PageForConfiguringItemTypes Then
		PageForSettingUpTypesOfNomenclatureOpening(ItSBackwardsTransition);
	ElsIf Page = Items.ThePageForStartingTheAutomaticTransition Then
		PageForLaunchingAutomaticTransitionOpening(ItSBackwardsTransition);
	ElsIf Page = Items.PageWait Then
		WaitingPageOpening(ItSBackwardsTransition);
	ElsIf Page = Items.ErrorPage Then
		PageErrorOpening(ItSBackwardsTransition);
	ElsIf Page = Items.ResultPage Then
		OpeningResultPage(ItSBackwardsTransition);
	EndIf;
	
	Items.Pages.CurrentPage = Page;
	
EndProcedure

&AtClient
Procedure PageInitialOpening(ItSBackwardsTransition)
	
	Title = NStr("vi = 'Bước 1. Chuyển sang thiết lập giá 11.5';
				|ru = 'Шаг 1. Переход на ценообразование 11.5';
				|en = 'Step 1. Migration to pricing 11.5'; fa = 'Step 1. Migration to pricing 11.5';
				|it = 'Passaggio 1. Passaggio all''elaborazione di prezzo 11.5';
				|pl = 'Krok 1. Przejście do tworzenia cen 11.5';
				|tr = 'Adım 1. 11.5 fiyatlandırmasına geçiş'");
	AdjustPricingVersion(Title);
	Items.Back.Visible = False;
	
EndProcedure

&AtClient
Function PageStartNext()
	
	Return Items.PageForSelectingPriceTypes;
	
EndFunction

&AtClient
Procedure PriceSelectionPageOpening(ItSBackwardsTransition)
	
	Title = NStr("vi = 'Bước 2. Chọn dạng giá để tự động chuyển';
				|ru = 'Шаг 2. Выбор видов цен для автоматического переноса';
				|en = 'Step 2. Select price types for automatic transfer'; fa = 'Step 2. Select price types for automatic transfer';
				|it = 'Passaggio 2. Selezione dei tipi di prezzo per il trasferimento automatico';
				|pl = 'Krok 2. Wybór rodzajów dla automatycznego przeniesienia';
				|tr = 'Adım 2. Otomatik aktarma için fiyat türlerinin seçilmesi'");

	If Not ItSBackwardsTransition Then
		FillInTreeOfPriceTypes();
	EndIf;
	
EndProcedure

&AtClient
Function PageForSelectingTypesOfPricesNext()
	
	Return Items.PageForConfiguringItemTypes;
	
EndFunction

&AtClient
Procedure PageForSettingUpTypesOfNomenclatureOpening(ItSBackwardsTransition)
	
	Title = NStr("vi = 'Bước 3. Tùy chỉnh các khía cạnh thiết lập giá trong dạng mặt hàng';
				|ru = 'Шаг 3. Настройка разрезов ценообразования в видах номенклатуры';
				|en = 'Step 3. Set up pricing dimensions in item kinds'; fa = 'Step 3. Set up pricing dimensions in item kinds';
				|it = 'Passaggio 3. Impostazione delle sezioni di elaborazione di prezzo nei tipi di nomenclatura';
				|pl = 'Krok 3. Ustawienia przekrojów tworzenia cen w rodzajach pozycji';
				|tr = 'Adım 3. Öğe türlerinde fiyatlandırma kesitlerinin ayarı'");
	
EndProcedure

&AtClient
Function ProductTypesSettingsPageNext()
	
	Return Items.ThePageForStartingTheAutomaticTransition;
	
EndFunction

&AtClient
Procedure PageForLaunchingAutomaticTransitionOpening(ItSBackwardsTransition)
	
	Title = NStr("vi = 'Bước 4. Khởi chạy tự động chuyển đổi';
				|ru = 'Шаг 4. Запуск автоматического перехода';
				|en = 'Step 4. Starting automatic migration'; fa = 'Step 4. Starting automatic migration';
				|it = 'Passaggio 4. Avvio del passaggio automatico';
				|pl = 'Krok 4. Uruchomieniу przejścia automatycznego';
				|tr = 'Adım 4. Otomatik geçişin başlatılması'");
	
	Items.Next.Title = NStr("vi = 'Chuyển sang thiết lập giá mới >>';
							|ru = 'Перейти на новое ценообразование >>';
							|en = 'Migrate to new pricing >>'; fa = 'Migrate to new pricing >>';
							|it = 'Passare alla nuova elaborazione di prezzo >>';
							|pl = 'Przejdź do nowego tworzenia cen >>';
							|tr = 'Yeni fiyatlandırmaya geç >>'");
	ChangeSuggestion("Next", NStr("vi = 'Chuyển sang thiết lập giá mới';
									|ru = 'Перейти на новое ценообразование';
									|en = 'Migrate to new pricing'; fa = 'Migrate to new pricing';
									|it = 'Passare alla nuova elaborazione di prezzo';
									|pl = 'Przejdź do nowego tworzenia cen';
									|tr = 'Yeni fiyatlandırmaya geç'"));
	
EndProcedure

&AtClient
Function PageForStartingAutomaticNavigationNext()

	StartSwitchingToPricingVersion2_5();
	
	Return Items.PageWait;
	
EndFunction

&AtClient
Function WaitingPageNext()
	
	Close();
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure WaitingPageOpening(ItSBackwardsTransition)

	Title = NStr("vi = 'Bước 5. Thực hiện chuyển đổi sang thiết lập giá phiên bản 11.5...';
				|ru = 'Шаг 5. Выполняется переход на ценообразование версии 11.5 ...';
				|en = 'Step 5. Migrating to pricing version 11.5 ...'; fa = 'Step 5. Migrating to pricing version 11.5 ...';
				|it = 'Fase 5. Passaggio all''elaborazione di prezzo versione 11.5 in corso...';
				|pl = 'Krok 5. Trwa przejście do tworzenia cen wersji 11.5 ...';
				|tr = 'Adım 5. 11.5 fiyatlandırma sürümüne geçiş gerçekleştirilmektedir...'");
	AdjustPricingVersion(Title);
	Items.Next.Visible = True;;
	Items.Next.Title = NStr("vi = 'Đóng trợ giúp';
							|ru = 'Закрыть помощник';
							|en = 'Close the wizard'; fa = 'بستن دستیار';
							|it = 'Chiudere l''assistente';
							|pl = 'Zamknij asystenta';
							|tr = 'Sihirbazı kapat'");
	Items.Back.Visible = False;
	
	ChangeSuggestion("Next", NStr("vi = 'Đóng trợ giúp';
									|ru = 'Закрыть помощник';
									|en = 'Close the wizard'; fa = 'بستن دستیار';
									|it = 'Chiudere l''assistente';
									|pl = 'Zamknij asystenta';
									|tr = 'Sihirbazı kapat'"));
	
	AttachIdleHandler("UpdatingTransitionStatus", 1, False);
	
EndProcedure

&AtClient
Function PageResultNext()
	
	Close();
	Return Undefined;
	
EndFunction

&AtClient
Procedure OpeningResultPage(ItSBackwardsTransition)
	
	Title = NStr("vi = 'Kết quả chuyển';
				|ru = 'Результат перехода';
				|en = 'Migration result'; fa = 'Migration result';
				|it = 'Risultato passaggio';
				|pl = 'Wynik przejścia';
				|tr = 'Geçiş sonucu'");
	
	Items.Next.Title = NStr("vi = 'Đồng ý';
							|ru = 'Готово';
							|en = 'Done'; fa = 'انجام شد';
							|it = 'Fine';
							|pl = 'Gotowe';
							|tr = 'Bitti'");
	Items.Cancel.Title = NStr("ru = 'Закрыть';
								|vi = 'Закрыть';
								|en = 'Закрыть'; fa = 'Закрыть';
								|it = 'Закрыть';
								|pl = 'Закрыть';
								|tr = 'Закрыть'");
	AdjustPricingVersion(Items.Cancel.Title);
	ChangeSuggestion("Next", NStr("vi = 'Đồng ý';
									|ru = 'Готово';
									|en = 'Done'; fa = 'انجام شد';
									|it = 'Fine';
									|pl = 'Gotowe';
									|tr = 'Bitti'"));
	ChangeSuggestion("Cancel", NStr("ru = 'Закрыть';
									|vi = 'Закрыть';
									|en = 'Закрыть'; fa = 'Закрыть';
									|it = 'Закрыть';
									|pl = 'Закрыть';
									|tr = 'Закрыть'"));

	Items.Back.Visible = False;

	UsePriceManagementSystem25 = True;
	Items.Cancel.Visible = False;
	Items.DecorationResult25.Visible = UsePriceManagementSystem25;

	Items.GroupPageResultInformation.Visible = ThereAreErrorsWhenTransferringPrices();

EndProcedure

&AtClient
Function ErrorPageNext()
	
	ClearTransitionState();
	Close();
	Return Undefined;
	
EndFunction

&AtClient
Procedure PageErrorOpening(ItSBackwardsTransition)
	
	Items.Next.Title = NStr("vi = 'Đồng ý';
							|ru = 'Готово';
							|en = 'Done'; fa = 'انجام شد';
							|it = 'Fine';
							|pl = 'Gotowe';
							|tr = 'Bitti'");	
	Items.Cancel.Visible = False;
	Items.Back.Visible = False;
	
	ChangeSuggestion("Next", NStr("vi = 'Đồng ý';
									|ru = 'Готово';
									|en = 'Done'; fa = 'انجام شد';
									|it = 'Fine';
									|pl = 'Gotowe';
									|tr = 'Bitti'"));
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure ChangeSuggestion(CommandName, ToolTip="")
	Commands[CommandName].ToolTip = ToolTip;
	AdjustPricingVersion(Commands[CommandName].ToolTip);
EndProcedure

&AtServer
Procedure FillInTreeOfPriceTypes()
	Var Tree;
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	ItemPricesCrossSectionOfTheLatest.PriceKind AS PriceKind,
	|	MAX(ItemPricesCrossSectionOfTheLatest.Period) AS Period
	|INTO DatesOfLastPriceSettings
	|FROM
	|	InformationRegister.ItemsPrices.SliceLast AS ItemPricesCrossSectionOfTheLatest
	|GROUP BY
	|	ItemPricesCrossSectionOfTheLatest.PriceKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TypesOfPrices.Ref AS Ref,
	|	TypesOfPrices.Parent AS Parent,
	|	TypesOfPrices.Description AS Description,
	|	TypesOfPrices.IsFolder AS IsFolder,
	|	TypesOfPrices.PriceCurrency AS Currency,
	|	NOT TypesOfPrices.IsFolder AS Selected,
	|	CASE
	|		WHEN TypesOfPrices.IsFolder
	|			THEN 0
	|		ELSE 2
	|	END AS Picture,
	|	CASE
	|		WHEN TypesOfPrices.IsFolder
	|			THEN DATETIME(1, 1, 1, 0, 0, 0)
	|		ELSE ISNULL(DatesOfLastPriceSettings.Period, DATETIME(1, 1, 1, 0, 0, 0))
	|	END AS DateOfTheLastPriceSetting,
	|	TypesOfPrices.BasicPriceType,
	|	TypesOfPrices.InfluencingPriceTypes.(
	|		Ref,
	|		LineNumber,
	|		InfluencingPriceType),
	|	TypesOfPrices.PricingMethod
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|		LEFT JOIN DatesOfLastPriceSettings AS DatesOfLastPriceSettings
	|		ON DatesOfLastPriceSettings.PriceKind = TypesOfPrices.Ref
	|WHERE
	|	NOT TypesOfPrices.DeletionMark
	|	AND (TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)
	|	OR TypesOfPrices.Status IS NULL)";
	
	Tree = FormAttributeToValue("TheTreeSelectedPrices", Type("ValueTree"));

	If Tree.Rows.Count() = 0 Then
		ArrayOfSelectedStrings = Undefined;
	Else	
		ArrayOfSelectedStrings = New Array;
		FindSelectedOnesInHierarchy(Tree.Rows, ArrayOfSelectedStrings);
		
		If TheTreeSelectedPricesDisplayOnlySelectedItems Then
			Query.Parameters.Insert("ArrayOfSelectedStrings",ArrayOfSelectedStrings);
				Query.Text = Query.Text+"
				|AND
		   		|	TypesOfPrices.Ref IN (&ArrayOfSelectedStrings)";
		EndIf;
	EndIf;
	
	Query.Text = Query.Text+"
	|ORDER BY
	|	Ref HIERARCHY";
	
	Tree.Rows.Clear();
	NewRow = Tree;
	Result = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	BuildHierarchy(Result.Rows, NewRow, True, ArrayOfSelectedStrings);
	
	ValueToFormData(Tree, TheTreeSelectedPrices);
	
EndProcedure

&AtServer
Procedure BuildHierarchy(Rows, TreeRow, ThisIsPriceTree = False, ArrayOfSelectedStrings = Undefined)
	
	For Each TSRow In Rows Do
		
		If ValueIsFilled(TSRow.Parent) And TSRow.Parent.Ref = TSRow.Ref Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(TSRow.Ref) Then
			BuildHierarchy(TSRow.Rows, TreeRow, ThisIsPriceTree, ArrayOfSelectedStrings);
			Continue;
		EndIf;
		
		NewRow = TreeRow.Rows.Add();
		FillPropertyValues(NewRow, TSRow);
		If ArrayOfSelectedStrings <> Undefined Then
			NewRow.Selected = Not ArrayOfSelectedStrings.Find(TSRow.Ref) = Undefined;
		EndIf;
		
		
		If ThisIsPriceTree Then
			NewRow.InfluencingPrices.LoadValues(TSRow.InfluencingPriceTypes.UnloadColumn("InfluencingPriceType"));
		EndIf;
		
		BuildHierarchy(TSRow.Rows, NewRow, ThisIsPriceTree, ArrayOfSelectedStrings);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ChangeSelectedFlagInPriceViewTree(Rows, FlagSelected = True)
	For Each TSRow In Rows Do
		
		If TSRow.IsFolder Then
			ChangeSelectedFlagInPriceViewTree(TSRow.Rows, FlagSelected);
			Continue;
		EndIf;
		
		TSRow.Selected = FlagSelected;
	EndDo;
EndProcedure

&AtServer
Procedure FindSelectedOnesInHierarchy(Rows, ArrayOfSelectedStrings)
	
	For Each TSRow In Rows Do
		
		If TSRow.IsFolder Then
			FindSelectedOnesInHierarchy(TSRow.Rows, ArrayOfSelectedStrings);
			Continue;
		EndIf;
		
		If TSRow.Selected Then
			ArrayOfSelectedStrings.Add(TSRow.Ref);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure StartSwitchingToPricingVersion2_5()
	
	MigrationParameters = SettingPricesServer.InitializeTransitionStateStructure();
	
	MigrationParameters.DateOfMigrationToPriceManagementSystem25 = DateOfMigrationToPriceManagementSystem25;
		
	// fill in the data for step 1 - creating an IPL
	QueryText = "SELECT
	|	TermsOfSale.Ref AS Ref
	|INTO TDTabAgreementsForProcessing
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|WHERE
	|	TermsOfSale.Status <> VALUE(Enum.StatusesOfTermsOfSales.Closed)
	|	AND (TermsOfSale.ValidityEndDate >= &TransitionDate
	|	OR TermsOfSale.ValidityEndDate = DATETIME(1, 1, 1))
	|	AND TermsOfSale.SpecialPriceType = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TDTabAgreementsForProcessing.Ref AS Ref
	|FROM
	|	TDTabAgreementsForProcessing AS TDTabAgreementsForProcessing
	|		INNER JOIN Catalog.TermsOfSale.PriceGroups AS TermsOfSalePriceGroups
	|		ON TDTabAgreementsForProcessing.Ref = TermsOfSalePriceGroups.Ref
	|
	|UNION
	|
	|SELECT
	|	TDTabAgreementsForProcessing.Ref
	|FROM
	|	TDTabAgreementsForProcessing AS TDTabAgreementsForProcessing
	|		INNER JOIN Catalog.TermsOfSale.Goods AS TermsOfSaleGoods
	|		ON TDTabAgreementsForProcessing.Ref = TermsOfSaleGoods.Ref";

	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;

	Query.SetParameter("TransitionDate", DateOfMigrationToPriceManagementSystem25);

	TableOfAgreements_ = Query.Execute().Unload();
	
	TableForProcessing = MigrationParameters.StepParameters1.TableForProcessing;//ValueTable
	
	For Each String In TableOfAgreements_ Do
		NewRow = TableForProcessing.Add();
		NewRow.Ref = String.Ref; 
		NewRow.State = Enums.JobsStates.Scheduled; 
	EndDo;

	MigrationParameters.StepParameters1.State = Enums.JobsStates.Scheduled; 
	MigrationParameters.StepParameters1.TotalCount1 = TableOfAgreements_.Count(); 
	
	// fill in the data for step 2 - checking and creating pricing sections
	QueryText = "SELECT DISTINCT
	|	CASE
	|		WHEN ItemKinds.ItemVariantsOwner = VALUE(Catalog.ItemKinds.EmptyRef)
	|			THEN ItemKinds.Ref
	|		ELSE ItemKinds.ItemVariantsOwner
	|	END AS Ref
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|WHERE
	|	ItemKinds.SettingsOfPriceKeyByItemVariant <> VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|
	|UNION
	|
	|SELECT
	|	CASE
	|		WHEN ItemKinds.BatchOwner = VALUE(Catalog.ItemKinds.EmptyRef)
	|			THEN ItemKinds.Ref
	|		ELSE ItemKinds.BatchOwner
	|	END
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|WHERE
	|	ItemKinds.SettingsOfPriceKeyByBatch <> VALUE(Enum.FilterOptionForPriceKey.DontUse)";

	Query = New Query(QueryText);

	TableForProcessing = MigrationParameters.StepParameters2.TableForProcessing;//ValueTable
	
	TableOfProductTypes = Query.Execute().Unload();
	For Each String In TableOfProductTypes Do

		NewRow = TableForProcessing.Add();
		NewRow.Ref = String.Ref;
		NewRow.State = Enums.JobsStates.Scheduled;
		 
	EndDo;

	MigrationParameters.StepParameters2.State = Enums.JobsStates.Scheduled; 
	MigrationParameters.StepParameters2.TotalCount1 = TableOfProductTypes.Count(); 
	
	// fill in the data for step 3 - price transfer
	Tree = FormAttributeToValue("TheTreeSelectedPrices", Type("ValueTree"));

	ArrayOfSelectedStrings = New Array;
	If Tree.Rows.Count() > 0 Then
		FindSelectedOnesInHierarchy(Tree.Rows, ArrayOfSelectedStrings);
		
		TableForProcessing = MigrationParameters.StepParameters3.TableForProcessing;//ValueTable
		
		For Each Item In ArrayOfSelectedStrings Do
			NewRow = TableForProcessing.Add();
			NewRow.Ref = Item; 
			NewRow.State = Enums.JobsStates.Scheduled; 
		EndDo;
	EndIf;
	
	MigrationParameters.StepParameters3.State = Enums.JobsStates.Scheduled; 
	MigrationParameters.StepParameters3.TotalCount1 = ArrayOfSelectedStrings.Count(); 
	
	SettingPricesServer.StartSwitchingToPricingVersion2_5(MigrationParameters);
	
EndProcedure

// Transition state.
// 
// Returns:
//  Structure - Transition state:
// * DateOfMigrationToPriceManagementSystem25 - Date -
// * StartDate - Date -
// * CompletedOn - Date -
// * Step - Number -
// * State - EnumRef.JobsStates -
// * StepParameters1 - see Initialize the structure of the transition parameters
// * StepParameters2 - see Initialize the structure of the transition parameters
// * StepParameters3 - see Initialize the structure of the transition parameters
&AtServerNoContext
Function TransitionState()
	
	TransitionState = SettingPricesServer.StateOfTransitionToPricingVersion2_5();
		
	Return TransitionState;
	
EndFunction

&AtClient
Procedure UpdatingTransitionStatus()
	
	UpdatingTransitionStatusOnServer();
	
	Items.Step1LabelCompleted.Visible 			= (TheStateOfStep1 = PredefinedValue("Enum.JobsStates.Completed"));
	Items.Step1TheLabelIsExecuted.Visible 			= (TheStateOfStep1 = PredefinedValue("Enum.JobsStates.Running"));
	Items.Step1TheLabelIsNotExecuted.Visible 		= (TheStateOfStep1 = PredefinedValue("Enum.JobsStates.Scheduled"));
	Items.Step1LabelMadeWithErrors.Visible 	= (TheStateOfStep1 = PredefinedValue("Enum.JobsStates.ExecutionError"));
	
	Items.Step2LabelCompleted.Visible 			= (StateStep2 = PredefinedValue("Enum.JobsStates.Completed"));
	Items.Step2TheLabelIsExecuted.Visible 			= (StateStep2 = PredefinedValue("Enum.JobsStates.Running"));
	Items.Step2TheLabelIsNotExecuted.Visible 		= (StateStep2 = PredefinedValue("Enum.JobsStates.Scheduled"));
	Items.Step2LabelMadeWithErrors.Visible 	= (StateStep2 = PredefinedValue("Enum.JobsStates.ExecutionError"));
	
	Items.Step3LabelCompleted.Visible 			= (StateStep3 = PredefinedValue("Enum.JobsStates.Completed"));
	Items.Step3TheLabelIsExecuted.Visible 			= (StateStep3 = PredefinedValue("Enum.JobsStates.Running"));
	Items.Step3TheLabelIsNotExecuted.Visible 		= (StateStep3 = PredefinedValue("Enum.JobsStates.Scheduled"));
	Items.Step3LabelMadeWithErrors.Visible 	= (StateStep3 = PredefinedValue("Enum.JobsStates.ExecutionError"));
	
	If ValueIsFilled(CompletedOn) Then
		
		DetachIdleHandler("UpdatingTransitionStatus");
		If ValueIsFilled(Job) Then
			If DisableExclusiveMode_() Then
				Job = Undefined;
				DetachIdleHandler("UpdatingTransitionStatus");
			EndIf;
		EndIf;
		
		If State = PredefinedValue("Enum.JobsStates.ExecutionError") Then
			NewPage = Items.ErrorPage;
		Else
			NewPage = Items.ResultPage;
		EndIf;
		
		Notify("Write_ConstantsSet", New Structure, "UsePriceManagementSystem25");
		
		OpeningPage(NewPage);
		
		If Not IsOpen() Then
			Open();
		EndIf;
		
	Else
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatingTransitionStatusOnServer()
	
	TransitionState = TransitionState();
	
	FillPropertyValues(ThisObject, TransitionState);
	
	TheStateOfStep1 = TransitionState.StepParameters1.State;
	StateStep2 = TransitionState.StepParameters2.State;
	StateStep3 = TransitionState.StepParameters3.State;

EndProcedure

&AtServer
Function ThereAreErrorsWhenTransferringPrices()
	
	TransitionState = TransitionState();
	
	Return (TransitionState.StepParameters3.ErrorsCount > 0);

EndFunction

&AtServer
Function GetPriceViewsWithErrors()
	
	TransitionState = TransitionState();
	
	ArrayOfPriceTypes = New Array();
	For Each String In TransitionState.StepParameters3.TableForProcessing Do//ValueTableRow
		If String.State = Enums.JobsStates.ExecutionError Then
			ArrayOfPriceTypes.Add(String.Ref);
		EndIf;
	EndDo;
	
	Return ArrayOfPriceTypes;

EndFunction

&AtServer
Procedure ClearTransitionState()
	
	InformationRegisters.StatusOfMigrationToPriceManagementSystemVersion25.CreateRecordSet().Write();
	
EndProcedure

&AtClient
Procedure BeforeClosingAlert(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Notify("Write_ConstantsSet", New Structure, "UsePriceManagementSystem25");
		CloseOfCourse = True;
		Close();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DisableExclusiveMode_()
	
	Try
		SetExclusiveMode(False);
	Except
		Return False;
	EndTry;

	Return True;
	
EndFunction

&AtClient
Procedure OnOpenForm(OnStart = False) Export
	
	If State = PredefinedValue("Enum.JobsStates.Completed") Then
		NewPage = Items.ResultPage;
	ElsIf State = PredefinedValue("Enum.JobsStates.ExecutionError") Then
		NewPage = Items.ErrorPage;
	ElsIf State = PredefinedValue("Enum.JobsStates.Running") 
		Or State = PredefinedValue("Enum.JobsStates.Scheduled") Then
		NewPage = Items.PageWait;
	Else
		If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
			Return;
		Else
			NewPage = Items.StartPage_;
		EndIf;	
	EndIf;
	
	OpeningPage(NewPage);
	
	If OnStart 
		And (ValueIsFilled(CompletedOn)) 
		And Not IsOpen() Then
		Open();
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	Items.DecorationInformationCheckingItemTypes1.Visible = UseItemVariants;
	
	Items.DecorationInformationCheckingItemTypes2.Visible = UseItemsBatch;
	
	Items.DecorationInformationCheckingItemTypes3.Visible = UseItemPackages;
	RenamePricingVersion();
EndProcedure
&AtServer
Procedure RenamePricingVersion()
	
	AdjustPricingVersion(Items.DecorationInformationHomePage.Title);
	AdjustPricingVersion(Items.DecorationInformationHomePage1.ToolTip);
	AdjustPricingVersion(Items.DateOfMigrationToPriceManagementSystem25.Title);
	AdjustPricingVersion(Items.DateOfTransitionToPricing1.Title);
	AdjustPricingVersion(Items.DecorationInformationForStartingAnAutomaticTransitionTitle.Title);
	AdjustPricingVersion(Items.InformationDecoration3.Title);
	AdjustPricingVersion(Items.DecorationResult25.Title);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustPricingVersion(LineToChange)
	LineToChange = StrReplace(LineToChange, "11.", "2.");
EndProcedure
&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheTreeSelectedPricesSelected.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheTreeSelectedPrices.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;	
	Item.Appearance.SetParameterValue("ReadOnly",True); 

EndProcedure

&AtClient
Procedure InformationDecoration4URLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("TypesOfPrices", GetPriceViewsWithErrors());
	
	OpenForm("DataProcessor.PriceList.Form.Form",FormParameters,, ThisForm.UUID,,,,);

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
