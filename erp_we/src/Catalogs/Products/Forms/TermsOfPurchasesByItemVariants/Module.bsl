
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Parameters.Property("Products", Products);
	
	FillList();
	
	AddingAgreementsIsAvailable = AccessRight("Insert", Metadata.Catalogs.TermsOfPurchaseFromVendors);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_TermsOfPurchaseFromVendors" Then
		FillList()
	EndIf;
	
EndProcedure

#EndRegion

#Region ListFormTableEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Field = Items.ListActionPresentation Then
		
		CurrentData	= Items.List.CurrentData;
		Hyperlink		= CurrentData.Action;
		
		PaddingValues = New Structure;
		PaddingValues.Insert("Partner",				CurrentData.Principal);
		PaddingValues.Insert("Counterparty",				CurrentData.Counterparty);
		PaddingValues.Insert("Status",					PredefinedValue("Enum.StatusesOfTermsOfPurchase.Valid"));
		PaddingValues.Insert("BusinessOperation",	PredefinedValue("Enum.BusinessTransactions.AgentServicesDelivery"));
		
		HyperlinkClickParameters = New Structure("FormName, FormParameters");
		
		If Hyperlink = "AgreementsToChoose"
			Or Hyperlink = "ListOfAgreementsByCharacteristics" Then
			
			PartnersForSelection = New Array;
			PartnersForSelection.Add(PredefinedValue("Catalog.Partners.EmptyRef"));
			PartnersForSelection.Add(CurrentData.Principal);
			
			CounterpartiesForSelection = New Array;
			CounterpartiesForSelection.Add(PredefinedValue("Catalog.Counterparties.EmptyRef"));
			CounterpartiesForSelection.Add(CurrentData.Counterparty);
			
			SelectionOfAgreements = New Structure;
			SelectionOfAgreements.Insert("Partner",					New FixedArray(PartnersForSelection));
			SelectionOfAgreements.Insert("Counterparty",				New FixedArray(CounterpartiesForSelection));
			SelectionOfAgreements.Insert("BusinessOperation",	PredefinedValue("Enum.BusinessTransactions.AgentServicesDelivery"));
			
			FilterCustom = New Structure;
			FilterCustom.Insert("State", PredefinedValue("Enum.StatesOfTermsOfPurchases.Valid"));
			
			ParametersForCreatingAgreement = New Structure;
			If Hyperlink = "AgreementsToChoose" Then
				PaddingValues.Insert("AgencyServiceProducts",	Products);
				PaddingValues.Insert("AgencyServiceCharacteristic",	CurrentData.Characteristic);
				
				ParametersForCreatingAgreement.Insert("TheseServices", PaddingValues);
			EndIf;
			
			FormParameters = New Structure;
			FormParameters.Insert("Filter",							SelectionOfAgreements);
			FormParameters.Insert("QuickFilterStructure",			FilterCustom);
			FormParameters.Insert("EnableAgencyServiceSelection",	Hyperlink = "ListOfAgreementsByCharacteristics");
			FormParameters.Insert("AgencyServiceProducts",		Products);
			FormParameters.Insert("AgencyServiceCharacteristic",	CurrentData.Characteristic);
			FormParameters.Insert("AdditionalParameters",			ParametersForCreatingAgreement);
			
			HyperlinkClickParameters.FormName			= "Catalog.TermsOfPurchaseFromVendors.ListForm";
			HyperlinkClickParameters.FormParameters	= FormParameters;
			
		ElsIf Hyperlink = "AgreementsToCreate" Then
			
			FormParameters = New Structure;
			FormParameters.Insert("FillingValues",				PaddingValues);
			FormParameters.Insert("AgencyServiceProducts",		Products);
			FormParameters.Insert("AgencyServiceCharacteristic",	CurrentData.Characteristic);
			
			HyperlinkClickParameters.FormName			= "Catalog.TermsOfPurchaseFromVendors.ObjectForm";
			HyperlinkClickParameters.FormParameters	= FormParameters;
			
		Else
			
			ExceptionText = NStr("vi = 'Chưa xác định thao tác chuyển khi nhấp vào hyperlink.';
								|ru = 'Неопределено действие перехода по гиперссылке.';
								|en = 'Hyperlink action is not identified.'; fa = 'Hyperlink action is not identified.';
								|it = 'Collegamento ipertestuale non definito.';
								|pl = 'Nieokreślone działanie przejścia z pomocą hiperłącza.';
								|tr = 'Köprü ile geçiş eylemi tanımsız.'");
			
			Raise ExceptionText;
			
		EndIf;
		
		OpenForm(HyperlinkClickParameters.FormName,
					HyperlinkClickParameters.FormParameters,
					,
					ThisForm.UUID,
					,
					,
					,
					ThisForm.WindowOpeningMode);
		
	ElsIf Field = Items.ListPrincipal Then
		ShowValue(, Items.List.CurrentData.Principal);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListActionPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ThereIsAgreementOnVariant");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AddingAgreementsIsAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor",		StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text",				NStr("vi = 'Chưa chọn trong thỏa thuận';
																	|ru = 'Не выбрана в соглашениях';
																	|en = 'Not selected in agreements'; fa = 'Not selected in agreements';
																	|it = 'Non selezionato negli accordi';
																	|pl = 'Nie wybrano w uzgadnianiach';
																	|tr = 'Anlaşmalarda seçilmedi'"));
	Item.Appearance.SetParameterValue("Enabled",		False);
	
EndProcedure

&AtServer
Procedure FillList()
	
	List.Clear();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CASE
	|		WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|			THEN CatProducts.Ref
	|		WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|			THEN CatProducts.ProductKind
	|		WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN CatProducts.ItemVariantsOwner
	|	END AS Ref
	|INTO ItemVariantsOwner
	|FROM
	|	Catalog.Products AS CatProducts
	|WHERE
	|	CatProducts.Ref = &Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsCharacteristics.Ref						AS Characteristic,
	|	ItemsCharacteristics.Principal					AS Principal,
	|	ItemsCharacteristics.Counterparty					AS Counterparty,
	|	MAX(NOT TermsOfPurchaseFromVendors.Ref IS NULL)	AS ThereAreAgreements,
	|	SUM(CASE
	|			WHEN NOT TSAgentServices.Ref IS NULL
	|					OR NOT TermsOfPurchaseFromVendors.UseSpecifiedAgentServices
	|				THEN 1
	|			ELSE 0
	|		END)												AS NumberOfAgreements,
	|	MAX(NOT TSAgentServices.Ref IS NULL
	|		OR NOT ISNULL(TermsOfPurchaseFromVendors.UseSpecifiedAgentServices, TRUE)) AS ThereIsAgreementOnVariant
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|		ON ItemsCharacteristics.Principal = TermsOfPurchaseFromVendors.Partner
	|			AND (ItemsCharacteristics.Counterparty = TermsOfPurchaseFromVendors.Counterparty
	|				OR TermsOfPurchaseFromVendors.Counterparty = VALUE(Catalog.Counterparties.EmptyRef))
	|			AND TermsOfPurchaseFromVendors.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|			AND TermsOfPurchaseFromVendors.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|			AND (TermsOfPurchaseFromVendors.ValidityStartDate = DATETIME(1, 1, 1)
	|				OR TermsOfPurchaseFromVendors.ValidityStartDate  <= &CurrentDate)
	|			AND (TermsOfPurchaseFromVendors.ValidityEndDate = DATETIME(1, 1, 1)
	|				OR TermsOfPurchaseFromVendors.ValidityEndDate >= &CurrentDate)
	|		
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS TSAgentServices
	|		ON TermsOfPurchaseFromVendors.Ref = TSAgentServices.Ref
	|			AND TSAgentServices.Products = &Products
	|			AND TSAgentServices.Characteristic = ItemsCharacteristics.Ref
	|WHERE
	|	ItemsCharacteristics.Owner IN
	|			(SELECT
	|				ItemVariantsOwner.Ref
	|			FROM
	|				ItemVariantsOwner)
	|	AND NOT ItemsCharacteristics.DeletionMark
	|
	|GROUP BY
	|	ItemsCharacteristics.Ref,
	|	ItemsCharacteristics.Principal,
	|	ItemsCharacteristics.Counterparty
	|
	|ORDER BY
	|	ItemsCharacteristics.Presentation";
	
	Query.SetParameter("Products",	Products);
	Query.SetParameter("CurrentDate",	CurrentSessionDate());
	
	Terms1 = Query.Execute().Unload();
	
	For Each RowOfTables In Terms1 Do
		
		NewRow = List.Add();
		FillPropertyValues(NewRow, RowOfTables);
		
		If Not RowOfTables.ThereAreAgreements Then
			AgreementHyperlink = "AgreementsToCreate";
			HyperlinkHeader = NStr("vi = 'Tạo mới thỏa thuận';
									|ru = 'Создать соглашение';
									|en = 'Create agreement'; fa = 'ایجاد توافق‌نامه';
									|it = 'Creare un accordo';
									|pl = 'Nowa umowa';
									|tr = 'Anlaşma oluştur'");
		ElsIf Not RowOfTables.ThereIsAgreementOnVariant Then
			AgreementHyperlink = "AgreementsToChoose";
			HyperlinkHeader = NStr("vi = 'Chọn trong thỏa thuận hiện có';
									|ru = 'Выбрать в существующем соглашении';
									|en = 'Select in the existing agreement'; fa = 'Select in the existing agreement';
									|it = 'Selezionare in un accordo esistente';
									|pl = 'Wybierz w istniejącym porozumieniu';
									|tr = 'Mevcut anlaşmada seç'");
		Else
			AgreementHyperlink = "ListOfAgreementsByCharacteristics";
			
			StringOfAgreements = StringWithNumber(";%1 agreement_;;%1 agreements;%1 agreements;%1 agreements",
											RowOfTables.NumberOfAgreements,
											NumericValueType.Cardinal,
											"L=ru");
			
			HyperlinkHeader = NStr("vi = 'Được chọn trong %NumberOfAgreements%';
									|ru = 'Выбрано в %NumberOfAgreements%';
									|en = 'Selected in %NumberOfAgreements%'; fa = 'Selected in %NumberOfAgreements%';
									|it = 'Selezionato in %NumberOfAgreements%';
									|pl = 'Wybrano w %NumberOfAgreements%';
									|tr = '%NumberOfAgreements%''de seçildi'");
			HyperlinkHeader = StrReplace(HyperlinkHeader, "%NumberOfAgreements%", StringOfAgreements);
		EndIf;
		
		NewRow.Action				= AgreementHyperlink;
		NewRow.ActionPresentation	= HyperlinkHeader;
		
	EndDo;
	
EndProcedure

#EndRegion
