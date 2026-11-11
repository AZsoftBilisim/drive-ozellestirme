
#Region Private

// Server-side event handler Obrabatyvayutsya the company directory.
//
Procedure OrganizationsProcessingFormReceipt(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export
	
	If FormType = "ListForm" And Not GetFunctionalOption("UseMultipleCompanies") Then
		
		Parameters.Insert("Key", SettingsValueCached.GetDefaultOrganization());
		SelectedForm = "ItemForm";
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

// Server handler for the event processingreceiving data from the Business directory Selection.
//
Procedure OrganizationsProcessingSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	If Parameters.Property("SelectionOfCounterpartiesAndOrganizations") 
		And GetFunctionalOption("UseCustomerInvoiceIntercompany") 
		And Parameters.SearchString <> Undefined Then
		StandardProcessing = False;
		ChoiceData = Catalogs.Counterparties.GetChoiceData(Parameters);
		Return;
	EndIf;
	
	UseManagementCompany = GetFunctionalOption("UseManagementCompany");
	
	If Parameters.Property("Filter") Then
		Parameters.Filter.Insert("Status", Enums.BusinessUnitCompanyStatuses.Valid);
	Else
		Parameters.Insert("Filter", New Structure("Status", Enums.BusinessUnitCompanyStatuses.Valid));
	EndIf;

	If Not UseManagementCompany
		Or Parameters.Property("ChoosingAManagementOrganization")
		Or Parameters.Property("BusinessOperation")
		Or Parameters.Property("ModeForSelectingRelatedOrganizations") 
		Or Parameters.Property("DoNotSelectOrganization") Then
		
		StandardProcessing = False;
		
		Query 		= New Query;
		
		ArrayAdditionalSelection = New Array;
		SelectionNumber_ = 0;
		
		If Parameters.Property("Filter") Then
			
			Attributes 			 = Metadata.Catalogs.Companies.Attributes;
			StandardAttributes = New Array;
			For Each Item In Metadata.Catalogs.Companies.StandardAttributes Do
				StandardAttributes.Add(Item.Name);
			EndDo;
			
			For Each CurrentFilter In Parameters.Filter Do
				
				If Attributes.Find(CurrentFilter.Key) = Undefined
				 And StandardAttributes.Find(CurrentFilter.Key) = Undefined Then
					Continue;
				EndIf;
				
				SelectionNumber_ = SelectionNumber_ + 1;
				
				ArrayAdditionalSelection.Add("DataForGeneralFiltering.Organization." + CurrentFilter.Key + " IN (&FilterValue" + TrimAll(SelectionNumber_) + ")");
				Query.SetParameter("FilterValue" + TrimAll(SelectionNumber_), CurrentFilter.Value);
				
			EndDo;
			
		EndIf;
		
		FilterText1 = StrConcat(ArrayAdditionalSelection, Chars.LF + Chars.Tab + "And" + " ");
		
		OrganizationExclusionText = "";
		If Parameters.Property("DoNotSelectOrganization") Then
			OrganizationExclusionText = "DataForGeneralFiltering.Organization <> &DoNotSelectOrganization"
		EndIf;
		
		QueryText =
		"SELECT DISTINCT ALLOWED
		|	SeparateBusinessUnits.ParentCompany AS Ref
		|INTO ParentOrganizations
		|FROM
		|	Catalog.Companies AS SeparateBusinessUnits
		|WHERE
		|	SeparateBusinessUnits.BranchOffice
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT  ALLOWED
		|	Companies.Ref AS Ref,
		|	Companies.Presentation,
		|	Companies.Predefined,
		|	Companies.Description,
		|	CASE
		|		WHEN Companies.BranchOffice
		|				OR ParentOrganizations.Ref IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThisIsParentOrganization,
		|	Companies.BranchOffice AS ThisIsSeparateUnit,
		|	Companies.ParentCompany
		|INTO OrganizationData_
		|FROM
		|	Catalog.Companies AS Companies
		|		LEFT JOIN ParentOrganizations AS ParentOrganizations
		|		ON Companies.Ref = ParentOrganizations.Ref
		|WHERE
		|	Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FilteringData.Ref,
		|	FilteringData.Presentation,
		|	FilteringData.Predefined,
		|	FilteringData.Description,
		|	FilteringData.ThisIsParentOrganization,
		|	FilteringData.ThisIsSeparateUnit,
		|	FilteringData.ParentCompany,
		|	CASE
		|		WHEN FilteringData.Ref <> &Organization
		|				AND (FilteringData.ThisIsParentOrganization
		|					OR FilteringData.ThisIsSeparateUnit)
		|				AND (&Organization = VALUE(Catalog.Companies.EmptyRef)
		|					OR (FilteringData.Ref = &ParentCompany
		|						OR FilteringData.ParentCompany = &Organization
		|						OR &ParentCompany <> VALUE(Catalog.Companies.EmptyRef)
		|							AND FilteringData.ParentCompany = &ParentCompany))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS Interconnected
		|INTO DataForAlternativeFiltering
		|FROM
		|	OrganizationData_ AS FilteringData
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FilteringData.Ref AS Organization,
		|	FilteringData.Predefined,
		|	FilteringData.Description,
		|	FilteringData.Presentation
		|INTO DataForGeneralFiltering
		|FROM
		|	DataForAlternativeFiltering AS FilteringData
		|WHERE
		|	&ModeForSelectingRelatedOrganizations = ""WithoutSeparateDivisions""
		|	AND FilteringData.Ref <> &Organization
		|	AND NOT FilteringData.ThisIsSeparateUnit
		|
		|UNION ALL
		|
		|SELECT
		|	FilteringData.Ref,
		|	FilteringData.Predefined,
		|	FilteringData.Description,
		|	FilteringData.Presentation
		|FROM
		|	DataForAlternativeFiltering AS FilteringData
		|WHERE
		|	(&ModeForSelectingRelatedOrganizations = ""OnlyInterconnected""
		|				AND FilteringData.Interconnected)
		|			OR (&ModeForSelectingRelatedOrganizations = ""JustNotInterconnected""
		|				AND NOT FilteringData.Interconnected
		|				AND FilteringData.Ref <> &Organization)
		|
		|UNION ALL
		|
		|SELECT
		|	DataForAlternativeFiltering.Ref,
		|	DataForAlternativeFiltering.Predefined,
		|	DataForAlternativeFiltering.Description,
		|	DataForAlternativeFiltering.Presentation
		|FROM
		|	DataForAlternativeFiltering AS DataForAlternativeFiltering
		|WHERE
		|	&ModeForSelectingRelatedOrganizations = """"
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT 
		|	DataForGeneralFiltering.Organization
		|FROM
		|	DataForGeneralFiltering AS DataForGeneralFiltering
		|WHERE
		|	NOT((NOT &UseManagementCompany
		|				OR &ChoiceOfManagementOrganizationIsProhibited)
		|				AND DataForGeneralFiltering.Predefined)
		|	AND &SearchTerms
		|	AND &AdditionalSelection
		|	AND &DoNotSelectOrganization
		|
		|ORDER BY
		|	DataForGeneralFiltering.Description";
		
		QueryText = StrReplace(QueryText, "&AdditionalSelection", ?(FilterText1 <> "", FilterText1, "TRUE"));
		QueryText = StrReplace(QueryText, "&DoNotSelectOrganization", 
											?(OrganizationExclusionText <> "", OrganizationExclusionText, "TRUE"));
		
		SearchTerms = "DataForGeneralFiltering.Description LIKE &SearchString";
		
		For AdditionalLanguageNumber = 1 To NationalLanguageSupportServer.AdditionalLanguagesCount() Do
			
			If NationalLanguageSupportServer.IsAdditionalLangUsed(AdditionalLanguageNumber) Then
				
				LanguageConstantName = NationalLanguageSupportServer.LanguageConstantName(AdditionalLanguageNumber);
				If Metadata.Constants.Find(LanguageConstantName) = Undefined Then
					
					Continue;
					
				EndIf;
				
				AttributesNames = NationalLanguageSupportServer.AttributesNamesConsideringLangCode("Description", Constants[LanguageConstantName].Get());
				SearchTerms = SearchTerms + "
				|	OR " + StringFunctionsClientServer.SubstituteParametersToString("DataForGeneralFiltering.Organization.%1 LIKE &SearchString ESCAPE ""~""",
					AttributesNames["Description"]);
				
			EndIf;
			
		EndDo;
		
		QueryText = StrReplace(QueryText, "&SearchTerms", SearchTerms);
		
		Query.Text = QueryText;
		Query.TempTablesManager = New TempTablesManager;
		
		// In the selection parameters, the selection of a management organization is prohibited
		ChoiceOfManagementOrganizationIsProhibited = (Parameters.Property("ChoosingAManagementOrganization") 
													And Not Parameters.ChoosingAManagementOrganization);
													
		SearchString = ?(Parameters.SearchString = Undefined, "", Parameters.SearchString);
		
		ModeForSelectingRelatedOrganizations = "";
		If Parameters.Property("ModeForSelectingRelatedOrganizations") Then
			
			If Parameters.ModeForSelectingRelatedOrganizations = "ForRegistrationWithTaxAuthority" Then
				If CompaniesLocalization.RegistrationForSeparateDivisionsIsPossible() Then
					ModeForSelectingRelatedOrganizations = "";
				Else
					ModeForSelectingRelatedOrganizations = "WithoutSeparateDivisions";
				EndIf;
			Else
				ModeForSelectingRelatedOrganizations = Parameters.ModeForSelectingRelatedOrganizations;
			EndIf;
		
		ElsIf Parameters.Property("BusinessOperation") Then
			
			ListBT = New Array;
			ListBT.Add(Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices);
			ListBT.Add(Enums.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices);
			ListBT.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices);
			ListBT.Add(Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices);
			ListBT.Add(Enums.BusinessTransactions.TransferOfFixedAssetsToBranchOffice);
			ListBT.Add(Enums.BusinessTransactions.TransferIntangibleAssetsToBranchOffice);
			
			
			If ListBT.Find(Parameters.BusinessOperation) <> Undefined Then
				ModeForSelectingRelatedOrganizations = "OnlyInterconnected";
			EndIf;
		
		EndIf;
		
		Organization			= ?(Parameters.Property("Organization"), Parameters.Organization, Catalogs.Companies.EmptyRef());
		ParentCompany	= Common.ObjectAttributeValue(Organization, "ParentCompany");
		
		Query.SetParameter("UseManagementCompany", 	UseManagementCompany);
		Query.SetParameter("ChoiceOfManagementOrganizationIsProhibited", ChoiceOfManagementOrganizationIsProhibited);
		Query.SetParameter("SearchString", 							SearchString + "%");
		Query.SetParameter("ModeForSelectingRelatedOrganizations", 	ModeForSelectingRelatedOrganizations);
		Query.SetParameter("Organization", 							Organization);
		Query.SetParameter("ParentCompany", 					ParentCompany);
		
		If Parameters.Property("DoNotSelectOrganization") Then
			Query.SetParameter("DoNotSelectOrganization", Parameters.DoNotSelectOrganization);
		EndIf;
			 		
		ChoiceData = New ValueList;
		ChoiceData.LoadValues(Query.Execute().Unload().UnloadColumn("Organization"));

	EndIf;	
	
EndProcedure


#EndRegion