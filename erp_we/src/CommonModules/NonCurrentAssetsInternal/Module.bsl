////////////////////////////////////////////////////////////////////////////////
// Contains service procedures and functions of the "Non-current Assets" subsystem.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region AccountingChecks_

Function ThereIsAccountingOfNonCurrentAssets2_4() Export

	ListOfMergeRequests = New Array;
	
	QueryText = 
	"SELECT TOP 1
	|	Table.Recorder
	|FROM
	|	InformationRegister.FALocation AS Table
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Table.Recorder
	|FROM
	|	InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting AS Table
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Table.Recorder
	|FROM
	|	InformationRegister.FixedAssetDepreciationParametersManagementAccounting AS Table
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Table.Recorder
	|FROM
	|	InformationRegister.InitialIntangibleAssetsInformation AS Table
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Table.Recorder
	|FROM
	|	InformationRegister.InitialFixedAssetsInformation AS Table
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Table.Recorder
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedure AS Table
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Table.Recorder
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure AS Table";
	ListOfMergeRequests.Add(QueryText);
	
	NonCurrentAssetsLocalization.ToSupplementTextOfRequestThereIsAccountingOfNonCurrentAssets2_4(ListOfMergeRequests);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	Query = New Query(QueryText);
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Not Result.IsEmpty();

EndFunction

Function ThereIsAccountingOfNonCurrentAssets() Export

	ListOfMergeRequests = New Array;
	
	NonCurrentAssetsLocalization.ToSupplementTextOfRequestThereIsAccountingOfNonCurrentAssets(ListOfMergeRequests);
	
	If ListOfMergeRequests.Count() = 0 Then
		Return False;
	EndIf;
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	Query = New Query(QueryText);
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Not Result.IsEmpty();

EndFunction

Procedure CheckPossibilityOfTakingIntoAccountFA(Object, Cancel) Export

	QueryText = 
	"SELECT
	|	Assets.Ref,
	|	Assets.Presentation,
	|
	|	Assets.CurrentCompany,
	|	Assets.CurrentLocation,
	|	Assets.CurrentPIER,
	|
	|	Assets.DeregistrationDocumentACC,
	|	Assets.DeregistrationDocumentTA,
	|	Assets.DeregistrationDocumentMA,
	|
	|	Assets.AlreadyTakenIntoAccount,
	|	Assets.OtherCompany_,
	|	Assets.OtherLocation,
	|	Assets.AnotherPIER
	|FROM
	|	(SELECT
	|		Assets.Ref AS Ref,
	|		Assets.Presentation AS Presentation,
	|
	|		FALocation.Organization AS CurrentCompany,
	|		FALocation.FixedAssetsLocation AS CurrentLocation,
	|		FALocation.FinanciallyLiablePerson AS CurrentPIER,
	|
	|		ISNULL(InitialFixedAssetsInformation.DeregistrationDocumentACC, UNDEFINED) AS DeregistrationDocumentACC,
	|		ISNULL(InitialFixedAssetsInformation.DeregistrationDocumentTA, UNDEFINED) AS DeregistrationDocumentTA,
	|		ISNULL(InitialFixedAssetsInformation.DeregistrationDocumentMA, UNDEFINED) AS DeregistrationDocumentMA,
	|
	|		&RecordInManAccounting
	|				AND ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_)
	|			OR &PostInAccounting
	|				AND ISNULL(AccountingProcedureForOSBU.BUState, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_)
	|			OR &RecordInTA
	|				AND ISNULL(AccountingProcedureForOSBU.StateTa, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_) AS AlreadyTakenIntoAccount,
	|
	|		(NOT &RecordInManAccounting OR NOT &RecordInLocalAccounting)
	|			AND NOT FALocation.Organization IS NULL
	|			AND (&RecordInLocalAccounting AND ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_)
	|				OR &RecordInManAccounting AND ISNULL(AccountingProcedureForOSBU.BUState, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_)
	|				OR &RecordInManAccounting AND ISNULL(AccountingProcedureForOSBU.StateTa, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_))
	|			AND ISNULL(FALocation.Organization, UNDEFINED) <> &Organization
	|			AND &Organization <> VALUE(Catalog.Companies.EmptyRef) AS OtherCompany_,
	|
	|		(NOT &RecordInManAccounting OR NOT &RecordInLocalAccounting)
	|			AND NOT FALocation.FixedAssetsLocation IS NULL
	|			AND (&RecordInLocalAccounting AND ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_)
	|				OR &RecordInManAccounting AND ISNULL(AccountingProcedureForOSBU.BUState, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_)
	|				OR &RecordInManAccounting AND ISNULL(AccountingProcedureForOSBU.StateTa, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_))
	|			AND (ISNULL(FALocation.FixedAssetsLocation, UNDEFINED) <> &FixedAssetsLocation
	|					AND &FixedAssetsLocation <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|				OR &LocationInTabularPart) AS OtherLocation,
	|
	|		(NOT &RecordInManAccounting OR NOT &RecordInLocalAccounting)
	|			AND NOT FALocation.FinanciallyLiablePerson IS NULL
	|			AND (&RecordInLocalAccounting AND ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_)
	|				OR &RecordInManAccounting AND ISNULL(AccountingProcedureForOSBU.BUState, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_)
	|				OR &RecordInManAccounting AND ISNULL(AccountingProcedureForOSBU.StateTa, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_))
	|			AND (ISNULL(FALocation.FinanciallyLiablePerson, UNDEFINED) <> &FinanciallyLiablePerson 
	|					AND &FinanciallyLiablePerson <> VALUE(Catalog.Persons.EmptyRef)
	|				OR &LocationInTabularPart) AS AnotherPIER
	|	FROM
	|		Catalog.Assets AS Assets
	|
	|			LEFT JOIN InformationRegister.InitialFixedAssetsInformation.SliceLast(
	|					&Period,
	|					Recorder <> &Ref
	|						AND CorrectionDate = DATETIME(1,1,1)
	|						AND NOT Recorder REFS Document.SigningOfLeaseContract
	|						AND Organization = &Organization
	|						AND FixedAsset IN (&ListOfFA)) AS InitialFixedAssetsInformation
	|			ON (InitialFixedAssetsInformation.FixedAsset = Assets.Ref)
	|
	|			LEFT JOIN InformationRegister.FALocation.SliceLast(
	|					&Period,
	|					Recorder <> &Ref
	|						AND CorrectionDate = DATETIME(1,1,1)
	|						AND FixedAsset IN (&ListOfFA)) AS FALocation
	|			ON (FALocation.FixedAsset = Assets.Ref)
	|
	|			LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|					&Period,
	|					Recorder <> &Ref
	|						AND CorrectionDate = DATETIME(1,1,1)
	|						AND FixedAsset IN (&ListOfFA)) AS AccountingProcedureForOSBU
	|			ON (AccountingProcedureForOSBU.FixedAsset = FALocation.FixedAsset)
	|				AND (AccountingProcedureForOSBU.Organization = FALocation.Organization)
	|
	|			LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|					&Period,
	|					Recorder <> &Ref
	|						AND CorrectionDate = DATETIME(1,1,1)
	|						AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedureManagementAccounting
	|			ON (FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = FALocation.FixedAsset)
	|				AND (FixedAssetsAccountingProcedureManagementAccounting.Organization = FALocation.Organization)
	|	WHERE
	|		Assets.Ref IN(&ListOfFA)
	|	
	|	) AS Assets
	|WHERE
	|	(Assets.AlreadyTakenIntoAccount
	|			OR Assets.OtherCompany_
	|			OR Assets.OtherLocation
	|			OR Assets.AnotherPIER)";
	
	Query = New Query(QueryText);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	Query.SetParameter("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Period", Object.Date);
	
	If TypeOf(Object) = Type("DocumentObject.FixedAssetsInitialRecognition2_4") Then
		Query.SetParameter("FINANCIALLYLIABLEPERSON", Object.FinanciallyLiablePerson);
		Query.SetParameter("FixedAssetsLocation", Object.FixedAssetsLocation);
	ElsIf TypeOf(Object) = Type("DocumentObject.MergeOfFixedAssets") Then
		Query.SetParameter("FINANCIALLYLIABLEPERSON", Object.FinanciallyLiablePerson);
		Query.SetParameter("FixedAssetsLocation", Object.Department);
	ElsIf TypeOf(Object) = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4") Then
		Query.SetParameter("FINANCIALLYLIABLEPERSON", Catalogs.Persons.EmptyRef());
		Query.SetParameter("FixedAssetsLocation", Object.FixedAssetsLocation);
	ElsIf TypeOf(Object) = Type("DocumentObject.SplitFixedAssets") Then
		Query.SetParameter("FINANCIALLYLIABLEPERSON", Catalogs.Persons.EmptyRef());
		Query.SetParameter("FixedAssetsLocation", Object.Department);
	Else
		Query.SetParameter("FINANCIALLYLIABLEPERSON", Catalogs.Persons.EmptyRef());
		Query.SetParameter("FixedAssetsLocation", Catalogs.BusinessStructure.EmptyRef());
	EndIf;
	
	If TypeOf(Object) = Type("DocumentObject.MergeOfFixedAssets") Then
		MainToolInHeader = True;
		Query.SetParameter("ListOfFA", CommonClientServer.ValueInArray(Object.FixedAsset));
	ElsIf TypeOf(Object) = Type("DocumentObject.RecognizeSubAssetsComponentsOfDepreciation") Then
		MainToolInHeader = False;
		Query.SetParameter("ListOfFA", Object.DepreciationComponents.UnloadColumn("DepreciationComponent"));
	Else
		MainToolInHeader = False;
		Query.SetParameter("ListOfFA", Object.FA.UnloadColumn("FixedAsset"));
	EndIf;
	
	LocationInTabularPart =
		TypeOf(Object) = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4")
			And Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty;
	Query.SetParameter("LocationInTabularPart", LocationInTabularPart);
	
	If TypeOf(Object) = Type("DocumentObject.FixedAssetsInitialRecognition2_4")
		Or TypeOf(Object) = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4") Then
		Query.SetParameter("PostInAccounting", Object.PostInAccounting);
		Query.SetParameter("RecordInTA", Object.RecordInTA);
	Else
		Query.SetParameter("PostInAccounting", Object.RecordInLocalAccounting);
		Query.SetParameter("RecordInTA", False);
	EndIf;
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	Selection = Result.Select();
	
	ThisIsInputOfResiduals = TypeOf(Object) = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4");
	
	If TypeOf(Object) = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4") Then
		NameOfPropsForMessage = "LineNumber";
	ElsIf TypeOf(Object) = Type("DocumentObject.RecognizeSubAssetsComponentsOfDepreciation") Then
		NameOfPropsForMessage = "DepreciationComponent";
	Else
		NameOfPropsForMessage = "FixedAsset";
	EndIf; 
	
	TextNotSpecified = NStr("vi = '<Chưa chỉ ra>';
							|ru = '<Не указан>';
							|en = '<not specified>'; fa = '<مشخص نشده>';
							|it = '<non specificato>';
							|pl = '<Nie określono>';
							|tr = '<Belirtilmedi>'");
			
	While Selection.Next() Do
		
		If MainToolInHeader Then
			Path = "Object";
			RowData = Undefined;
		Else
			If TypeOf(Object) = Type("DocumentObject.RecognizeSubAssetsComponentsOfDepreciation") Then
				RowData = Object.DepreciationComponents.Find(Selection.Ref, "DepreciationComponent");
				Path = CommonClientServer.PathToTabularSection("DepreciationComponents", RowData.LineNumber, NameOfPropsForMessage);
			Else
				RowData = Object.FA.Find(Selection.Ref, "FixedAsset");
				Path = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, NameOfPropsForMessage);
			EndIf;
		EndIf;
		
		If Selection.AlreadyTakenIntoAccount Then
			
			If ValueIsFilled(Selection.DeregistrationDocumentMA) Then
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" đã được hủy đăng ký trong doanh nghiệp %2. Chấp nhận lại cho cùng một doanh nghiệp không được hỗ trợ.';
									|ru = 'Основное средство ""%1"" было снято с учета в организации %2. Повторное принятие к учету в ту же организацию не поддерживается.';
									|en = 'The ""%1"" fixed asset was derecognized in the %2 company. Cannot recognize it in the same company twice.'; fa = 'The ""%1"" fixed asset was derecognized in the %2 company. Cannot recognize it in the same company twice.';
									|it = 'Il capitale fisso ""%1"" è stato rimosso dalla contabilità dell''azienda %2. Non è possibile accettare nuovamente in contabilità la medesima azienda.';
									|pl = 'Środek trwały ""%1"" został skreślony z ewidencji w firmie %2. Ponowne przyjęcie do ewidencji do tej samej firmy nie jest obsługiwane.';
									|tr = '""%1"" sabit kıymeti %2 iş yerinde bilanço dışı bırakıldı. Aynı iş yerinde yeniden muhasebeleştirme desteklenmemektedir.'");
				MessageText = StrTemplate(MessageText, Selection.Presentation, Object.Organization);
			ElsIf ThisIsInputOfResiduals Then
				If ValueIsFilled(Object.RentalContract)
					And TypeOf(Object.RentalContract) = Type("CatalogRef.CounterpartyContracts")
					And Common.ObjectAttributeValue(
						Object.RentalContract, "ContractType") = Enums.ContractTypes.Sublease Then
					Continue;
				EndIf;
				MessageText = StrTemplate(NStr("vi = 'Đã nhập số dư cho tài sản ""%1"".';
												|ru = 'По основному средству ""%1"" уже введены остатки.';
												|en = 'Balance is already entered by the ""%1"" fixed asset.'; fa = 'Balance is already entered by the ""%1"" fixed asset.';
												|it = 'Sono già stati eseguiti i saldi per il capitale fisso ""%1"".';
												|pl = 'Według środka trwałego ""%1"" już są wprowadozone ostatki.';
												|tr = 'Sabit kıymet ""%1"" için bakiyeler zaten girilmiştir.'"), Selection.Presentation);
			Else
				MessageText = StrTemplate(NStr("vi = 'Tài sản cố định ""%1"" đã được tính.';
												|ru = 'Основное средство ""%1"" уже принято к учету.';
												|en = 'The ""%1"" fixed asset is already recognized.'; fa = 'The ""%1"" fixed asset is already recognized.';
												|it = 'Il capitale fisso ""%1"" è già stato registrato nella contabilità.';
												|pl = 'Środki trwałe ""%1"" są już przyjęte do ewidencji';
												|tr = 'Sabit kıymet ""%1"" zaten dikkate alınmıştır.'"), Selection.Presentation);
			EndIf; 
			Common.MessageToUser(MessageText, Object, Path,, Cancel);
			
			If ValueIsFilled(Selection.DeregistrationDocumentACC)
				Or ValueIsFilled(Selection.DeregistrationDocumentTA) Then
				
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" đã được hủy đăng ký trong doanh nghiệp %2. Chấp nhận lại cho cùng một doanh nghiệp không được hỗ trợ.';
									|ru = 'Основное средство ""%1"" было снято с учета в организации %2. Повторное принятие к учету в ту же организацию не поддерживается.';
									|en = 'The ""%1"" fixed asset was derecognized in the %2 company. Cannot recognize it in the same company twice.'; fa = 'The ""%1"" fixed asset was derecognized in the %2 company. Cannot recognize it in the same company twice.';
									|it = 'Il capitale fisso ""%1"" è stato rimosso dalla contabilità dell''azienda %2. Non è possibile accettare nuovamente in contabilità la medesima azienda.';
									|pl = 'Środek trwały ""%1"" został skreślony z ewidencji w firmie %2. Ponowne przyjęcie do ewidencji do tej samej firmy nie jest obsługiwane.';
									|tr = '""%1"" sabit kıymeti %2 iş yerinde bilanço dışı bırakıldı. Aynı iş yerinde yeniden muhasebeleştirme desteklenmemektedir.'");
				MessageText = StrTemplate(MessageText, Selection.Presentation, Object.Organization);
				Common.MessageToUser(MessageText, Object, Path,, Cancel);
			EndIf; 
			
		EndIf;
		
		If Selection.OtherCompany_ And Not Selection.AlreadyTakenIntoAccount Then
			
			If Object.RecordInManAccounting Then
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" phải được tiếp nhận vào doanh nghiệp ""%2"" phù hợp với kế toán tài chính.';
									|ru = 'Основное средство ""%1"" должно быть принято в организацию ""%2"", соответствующую регламентированному учету.';
									|en = 'The ""%1"" fixed asset must be entered into the ""%2"" company corresponding to local accounting.'; fa = 'The ""%1"" fixed asset must be entered into the ""%2"" company corresponding to local accounting.';
									|it = 'The ""%1"" fixed asset must be entered into the ""%2"" company corresponding to local accounting.';
									|pl = 'The ""%1"" fixed asset must be entered into the ""%2"" company corresponding to local accounting.';
									|tr = '""%1"" sabit kıymeti, yerel muhasebeye uygun olarak ""%2"" iş yerine kabul edilmelidir.'");
			Else
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" phải được tiếp nhận vào doanh nghiệp ""%2"" phù hợp với kế toán quản trị.';
									|ru = 'Основное средство ""%1"" должно быть принято в организацию ""%2"", соответствующую управленческому учету.';
									|en = 'The ""%1"" fixed asset must be entered into the ""%2"" company corresponding to management accounting.'; fa = 'The ""%1"" fixed asset must be entered into the ""%2"" company corresponding to management accounting.';
									|it = 'The ""%1"" fixed asset must be entered into the ""%2"" company corresponding to management accounting.';
									|pl = 'The ""%1"" fixed asset must be entered into the ""%2"" company corresponding to management accounting.';
									|tr = '""%1"" sabit kıymeti, yönetim muhasebesine uygun olarak ""%2"" iş yerine kabul edilmelidir.'");
			EndIf; 
			
			MessageText = StrTemplate(MessageText, Selection.Presentation, Selection.CurrentCompany);
			CommonClientServer.MessageToUser(MessageText, Object, Path,, Cancel);
			
		EndIf;
		
		If Selection.OtherLocation And Not Selection.AlreadyTakenIntoAccount 
			And (Not LocationInTabularPart Or RowData.Department <> Selection.CurrentLocation) Then
			
			If Object.RecordInManAccounting Then
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" phải được tiếp nhận vào bộ phận ""%2"" phù hợp với kế toán tài chính.';
									|ru = 'Основное средство ""%1"" должно быть принято в подразделение ""%2"", соответствующее регламентированному учету.';
									|en = 'The ""%1"" fixed asset must be entered into the ""%2"" business unit corresponding to local accounting.'; fa = 'The ""%1"" fixed asset must be entered into the ""%2"" business unit corresponding to local accounting.';
									|it = 'The ""%1"" fixed asset must be entered into the ""%2"" business unit corresponding to local accounting.';
									|pl = 'The ""%1"" fixed asset must be entered into the ""%2"" business unit corresponding to local accounting.';
									|tr = '""%1"" sabit kıymeti, yerel muhasebeye uygun ""%2"" departmanına kabul edilmelidir.'");
			Else
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" phải được tiếp nhận vào bộ phận ""%2"" phù hợp với kế toán quản trị.';
									|ru = 'Основное средство ""%1"" должно быть принято в подразделение ""%2"", соответствующее управленческому учету.';
									|en = 'The ""%1"" fixed asset must be entered into the ""%2"" business unit corresponding to management accounting.'; fa = 'The ""%1"" fixed asset must be entered into the ""%2"" business unit corresponding to management accounting.';
									|it = 'The ""%1"" fixed asset must be entered into the ""%2"" business unit corresponding to management accounting.';
									|pl = 'The ""%1"" fixed asset must be entered into the ""%2"" business unit corresponding to management accounting.';
									|tr = '""%1"" sabit kıymeti, yönetim muhasebesine uygun ""%2"" departmanına kabul edilmelidir.'");
			EndIf; 
			
			MessageText = StrTemplate(MessageText, Selection.Presentation, Selection.CurrentLocation);
			CommonClientServer.MessageToUser(MessageText, Object, Path,, Cancel);
			
		EndIf;
		
		If Selection.AnotherPIER And Not Selection.AlreadyTakenIntoAccount
			And (Not LocationInTabularPart Or RowData.FinanciallyLiablePerson <> Selection.CurrentPIER) Then
			
			If Object.RecordInManAccounting Then
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" phải được tiếp nhận với người có trách nhiệm vật chất ""%2"" phù hợp với kế toán tài chính.';
									|ru = 'Основное средство ""%1"" должно быть принято с МОЛ ""%2"", соответствующему регламентированному учету.';
									|en = 'The ""%1"" fixed asset must be entered with responsible employee ""%2"" corresponding to local accounting.'; fa = 'The ""%1"" fixed asset must be entered with responsible employee ""%2"" corresponding to local accounting.';
									|it = 'The ""%1"" fixed asset must be entered with responsible employee ""%2"" corresponding to local accounting.';
									|pl = 'The ""%1"" fixed asset must be entered with responsible employee ""%2"" corresponding to local accounting.';
									|tr = '""%1"" sabit kıymeti, yerel muhasebeye uygun olarak maddi sorumlu ""%2"" ye zimmetlenerek kabul edilmelidir.'");
			Else
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" phải được tiếp nhận với người có trách nhiệm vật chất ""%2"" phù hợp với kế toán quản trị.';
									|ru = 'Основное средство ""%1"" должно быть принято с МОЛ ""%2"", соответствующему в управленческому учету.';
									|en = 'The ""%1"" fixed asset must be entered with responsible employee ""%2"" corresponding to management accounting.'; fa = 'The ""%1"" fixed asset must be entered with responsible employee ""%2"" corresponding to management accounting.';
									|it = 'The ""%1"" fixed asset must be entered with responsible employee ""%2"" corresponding to management accounting.';
									|pl = 'The ""%1"" fixed asset must be entered with responsible employee ""%2"" corresponding to management accounting.';
									|tr = '""%1"" sabit kıymeti, yönetim muhasebesine uygun olarak maddi sorumlu ""%2"" ye zimmetlenerek kabul edilmelidir.'");
			EndIf; 
			MessageText = StrTemplate(MessageText, Selection.Presentation, ?(ValueIsFilled(Selection.CurrentPIER), Selection.CurrentPIER, TextNotSpecified));
			CommonClientServer.MessageToUser(MessageText, Object, Path,, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks the details of the operating system when they are accepted for accounting.
// 
// Parameters:
//  Object - DocumentObject.EntryOfCapitalAssetsBalance2_4, DocumentObject.MergeOfFixedAssets, DocumentObject.FixedAssetsInitialRecognition2_4, DocumentObject.SplitFixedAssets -
//  TSName - String - The name of the tabular part of the document.
//  Cancel - Boolean - 
Procedure CheckDetailsOfFAWhenTakingIntoAccount(Object, TSName, Cancel) Export

	Query = New Query;
	
	QueryText = NonCurrentAssetsLocalization.QueryTextCheckDetailsOfFAWhenTakingIntoAccount(Query, Object);
	If QueryText = Undefined Then
		QueryText = 
		"SELECT
		|	Assets.Ref AS Ref,
		|	Assets.Presentation AS Presentation,
		|	TRUE AS InventoryNumberNotFilledIn
		|FROM
		|	Catalog.Assets AS Assets
		|WHERE
		|	Assets.Ref IN(&ListOfFA)
		|	AND Assets.AssetID = """"
		|	AND Assets.OSType IN (
		|		VALUE(Enum.FATypes.Asset),
		|		VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets))";
	EndIf; 
	
	Query.Text = QueryText;
	Query.SetParameter("ListOfFA", ?(TSName <> Undefined, Object[TSName].UnloadColumn("FixedAsset"), Object.FixedAsset));
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Period", Object.Date);
	
	Result = Query.Execute();
	Selection = Result.Select();
	Path = Undefined;
	While Selection.Next() Do
		
		If TSName <> Undefined Then
			RowData = Object[TSName].Find(Selection.Ref, "FixedAsset"); // LineOfATabularSection - 
			Path = CommonClientServer.PathToTabularSection(TSName, RowData.LineNumber, "FixedAsset");
		EndIf;
		
		If Selection.InventoryNumberNotFilledIn Then
			MessageText = StrTemplate(NStr("vi = 'Trong thẻ của tài sản cố định ""%1"", bạn cần điền số hàng tồn kho.';
											|ru = 'В карточке основного средства ""%1"" необходимо заполнить инвентарный номер.';
											|en = 'Fill in the inventory number in the card of the ""%1"" fixed asset.'; fa = 'Fill in the inventory number in the card of the ""%1"" fixed asset.';
											|it = 'È necessario indicare il numero di inventario sulla scheda el capitale fisso ""%1""';
											|pl = 'W karcie środka trwałego ""%1"" należy wypełnić numer inwentarzowego.';
											|tr = 'Sabit kıymet kartında ""%1"" stok numarasının doldurulması gerekir.'"), Selection.Presentation);
			Common.MessageToUser(MessageText, Selection.Ref, "AssetID",, Cancel);
		EndIf;
		
		NonCurrentAssetsLocalization.CheckDetailsOfFAWhenTakingIntoAccount(Selection, Object, Path, Cancel);
		
	EndDo;
	
EndProcedure

Procedure CheckPossibilityOfAcceptingIAForAccounting(Object, Cancel, NMAVHeader = False) Export
	
	QueryText = NonCurrentAssetsLocalization.QueryTextCheckPossibilityOfAcceptingIAForAccounting();
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	Objects_Accounting.Ref,
		|	Objects_Accounting.Presentation,
		|	Objects_Accounting.KindOfAccountingObject,
		|	Objects_Accounting.CurrentCompany,
		|	Objects_Accounting.CurrentDepartment,
		|	Objects_Accounting.DocumentWriteOffs,
		|	Objects_Accounting.AlreadyTakenIntoAccount
		|FROM
		|	(SELECT
		|		Objects_Accounting.Ref AS Ref,
		|		Objects_Accounting.Presentation AS Presentation,
		|		Objects_Accounting.KindOfAccountingObject AS KindOfAccountingObject,
		|		IntangibleAssetsRegistrationPlace.Organization AS CurrentCompany,
		|		IntangibleAssetsRegistrationPlace.Department AS CurrentDepartment,
		|		ISNULL(InitialInformation.DocumentWriteOffs, UNDEFINED) AS DocumentWriteOffs,
		|
		|		&RecordInManAccounting
		|				AND ISNULL(InitialInformation.DocumentOfRecognitionManagementAccounting, UNDEFINED) <> &Ref
		|				AND ISNULL(InitialInformation.DateOfRecognitionManagementAccounting, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS AlreadyTakenIntoAccount
		|
		|	FROM
		|		Catalog.IntangibleAssets AS Objects_Accounting
		|			LEFT JOIN InformationRegister.InitialIntangibleAssetsInformation.SliceLast(
		|					&Period,
		|					Recorder <> &Ref
		|						AND Organization = &Organization
		|						AND IntangibleAsset IN (&ListOfIA)) AS InitialInformation
		|			ON (InitialInformation.IntangibleAsset = Objects_Accounting.Ref)
		|			LEFT JOIN InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast(
		|					&Period,
		|					Recorder <> &Ref
		|						AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetsRegistrationPlace
		|			ON (IntangibleAssetsRegistrationPlace.IntangibleAsset = Objects_Accounting.Ref)
		|			LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
		|					&Period,
		|					Recorder <> &Ref
		|						AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetsAccountingProcedureManagementAccounting
		|			ON (IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset)
		|				AND (IntangibleAssetsAccountingProcedureManagementAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization)
		|	WHERE
		|		Objects_Accounting.Ref IN(&ListOfIA)) AS Objects_Accounting
		|WHERE
		|	Objects_Accounting.AlreadyTakenIntoAccount";
	
	EndIf; 
	
	Query = New Query(QueryText);
	If NMAVHeader Then
		Query.SetParameter("ListOfIA", Object.IntangibleAsset);
	Else
		Query.SetParameter("ListOfIA", Object.IA.UnloadColumn("IntangibleAsset"));
	EndIf;
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	Query.SetParameter("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Period", Object.Date);
	
	If TypeOf(Object) = Type("DocumentObject.IntangibleAssetsInitialRecognition2_4") Then
		Query.SetParameter("Department", Object.Department);
	ElsIf TypeOf(Object) = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4") Then
		Query.SetParameter("Department", Object.FixedAssetsLocation);
	Else
		Query.SetParameter("Department", Catalogs.BusinessStructure.EmptyRef());
	EndIf;
	
	If TypeOf(Object) = Type("DocumentObject.IntangibleAssetsInitialRecognition2_4") Then
		Query.SetParameter("PostInAccounting", Object.PostInAccounting);
		Query.SetParameter("RecordInTA", Object.RecordInTA);
	Else
		Query.SetParameter("PostInAccounting", Object.RecordInLocalAccounting);
		Query.SetParameter("RecordInTA", Object.RecordInLocalAccounting);
	EndIf;
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	Selection = Result.Select();
	
	If TypeOf(Object) = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4") Then
		NameOfPropsForMessage = "LineNumber";
	Else
		NameOfPropsForMessage = "IntangibleAsset";
	EndIf; 
	
	ThisIsInputOfResiduals =  TypeOf(Object) = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4");
	
	While Selection.Next() Do
		
		If NMAVHeader Then
			Path = "IntangibleAsset";
		Else
			RowData = Object.IA.Find(Selection.Ref, "IntangibleAsset");
			Path = CommonClientServer.PathToTabularSection("IA", RowData.LineNumber, NameOfPropsForMessage);
		EndIf;
			
		If Selection.AlreadyTakenIntoAccount Then
			
			If Selection.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
				If ValueIsFilled(Selection.DocumentWriteOffs) Then
					MessageText = NStr("vi = 'Chi phí Nghiên cứu và phát triển ""%1"" đã được xóa cho doanh nghiệp %2. Chấp nhận lại cho cùng một doanh nghiệp không được hỗ trợ.';
										|ru = 'Расходы на НИОКР ""%1"" были списаны в организации %2. Повторное принятие к учету в ту же организацию не поддерживается.';
										|en = 'The ""%1"" R&D expenses were written off in the %2 company. Cannot recognize it in the same company twice.'; fa = 'The ""%1"" R&D expenses were written off in the %2 company. Cannot recognize it in the same company twice.';
										|it = 'Le spese in Ricerca & Sviluppo ""%1"" sono state stornate presso l''azienda %2. Non è possibile accettare nuovamente in contabilità la medesima azienda.';
										|pl = 'Rozchody na prace naukowo-badawcze i doświadczalno-konstrukcyjne ""%1"" zostały rozchodowane w firmie %2. Ponowne przyjęcie do ewidencji w tej samej firmie nie jest obsługiwane.';
										|tr = '""%1"" Ar-Ge harcaması %2 iş yerinde kayıttan düşüldü. Aynı iş yerinde yeniden muhasebeleştirme desteklenmemektedir.'");
					MessageText = StrTemplate(MessageText, Selection.Presentation, Object.Organization);
				ElsIf ThisIsInputOfResiduals Then
					MessageText = StrTemplate(NStr("vi = 'Số dư đã được nhập cho Chi phí Nghiên cứu và phát triển ""%1"".';
													|ru = 'По расходам на НИОКР ""%1"" уже введены остатки.';
													|en = 'Balance is already entered by ""%1"" R&D expenses.'; fa = 'Balance is already entered by ""%1"" R&D expenses.';
													|it = 'Sono già stati eseguiti i saldi per le spese in Ricerca & Sviluppo ""%1"".';
													|pl = 'Według rozchodów na R&D ""%1"" już są wprowadzone ostatki.';
													|tr = 'Ar-Ge harcamaları için ""%1"" bakiyeler zaten getirilmiştir.'"), Selection.Presentation);
				Else
					MessageText = StrTemplate(NStr("vi = 'Chi phí Nghiên cứu và phát triển ""%1"" đã được tính đến.';
													|ru = 'Расходы на НИОКР ""%1"" уже приняты к учету.';
													|en = 'The ""%1"" R&D expenses are already recognized.'; fa = 'The ""%1"" R&D expenses are already recognized.';
													|it = 'Le spese in Ricerca & Sviluppo ""%1"" sono già incluse in contabilità.';
													|pl = 'Rozchody na R&D ""%1"" już są przyjęte do ewidencji.';
													|tr = '""%1"" Ar-Ge harcamaları zaten muhasebeye alınmıştır.'"), Selection.Presentation);
				EndIf;
			Else
				If ValueIsFilled(Selection.DocumentWriteOffs) Then
					MessageText = NStr("vi = 'Tài sản cố định vô hình ""%1""đã bị ghi giảm tại doanh nghiệp %2. Chấp nhận lại cho cùng một doanh nghiệp không được hỗ trợ.';
										|ru = 'Нематериальный актив ""%1"" был списан в организации %2. Повторное принятие к учету в ту же организацию не поддерживается.';
										|en = 'The ""%1"" intangible asset was written off in the %2 company. Cannot recognize it in the same company twice.'; fa = 'The ""%1"" intangible asset was written off in the %2 company. Cannot recognize it in the same company twice.';
										|it = 'Il bene immateriale ""%1"" è stato stornato presso l''azienda %2. Non è possibile accettare nuovamente in contabilità la medesima azienda.';
										|pl = 'Wartość niematerialna ""%1"" została rozchodowana w firmie %2. Powtórne przyjęcie do ewidencji w tej samej firmie nie jest obsługiwane.';
										|tr = '""%1"" maddi olmayan duran varlığı %2 iş yerinde kayıttan düşüldü. Aynı iş yerinde yeniden muhasebeleştirme desteklenmemektedir.'");
					MessageText = StrTemplate(MessageText, Selection.Presentation, Object.Organization);
				ElsIf ThisIsInputOfResiduals Then
					MessageText = StrTemplate(NStr("vi = 'Tài sản cố định vô hình ""%1""đã nhập số dư.';
													|ru = 'По нематериальному активу ""%1"" уже введены остатки.';
													|en = 'Balance is already entered by the ""%1"" intangible asset.'; fa = 'Balance is already entered by the ""%1"" intangible asset.';
													|it = 'Sono già stati eseguiti i saldi per il bene immateriale ""%1"".';
													|pl = 'Według wartości niematerialnej ""%1"" już są wprowadzone ostatki.';
													|tr = 'Maddi olmayan duran varlık ""%1"" için bakiyeler zaten girilmiştir.'"), Selection.Presentation);
				Else
					MessageText = StrTemplate(NStr("vi = 'Tài sản cố định vô hình ""%1"" đã được tính đến.';
													|ru = 'Нематериальный актив ""%1"" уже принят к учету.';
													|en = 'The ""%1"" intangible asset is already recognized.'; fa = 'The ""%1"" intangible asset is already recognized.';
													|it = 'Il bene immateriale ""%1"" è già stato registrato nella contabilità.';
													|pl = 'Aktywa niematerialne ""%1"" zostały już przyjęte do ewidencji.';
													|tr = 'Maddi olmayan duran varlık ""%1"" zaten muhasebeye alınmıştır.'"), Selection.Presentation);
				EndIf;
			EndIf;
			
			Common.MessageToUser(MessageText, Object, Path,, Cancel);
			
		EndIf; 
		
		NonCurrentAssetsLocalization.CheckPossibilityOfAcceptingIAForAccounting(Selection, Object, Path, Cancel);
		
	EndDo;
	
EndProcedure

// Verifies that fixed assets are accepted for accounting.
// 
// Parameters:
// 	Object - DocumentObject - 
// 	Cancel - Boolean -
// 
Procedure CheckThatFAIsTakenIntoAccount(Object, Cancel) Export

	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date) Then
		// There is no need to check, because the document will be checked before the start date of accounting.
		Return;
	EndIf;
	
	StatesAccepted = New Array;
	StatesAccepted.Add(Enums.FixedAssetsStates.Recognized_);
	StatesAccepted.Add(Enums.FixedAssetsStates.EnteredInOffBalanceAccounting);
	
	DocumentType = TypeOf(Object);
	
	If DocumentType = Type("DocumentObject.FATransfer2_4")
		Or DocumentType = Type("DocumentObject.PreparingForFixedAssetSale2_4")
		Or DocumentType = Type("DocumentObject.LeaseTermAdjustment")
		Or DocumentType = Type("DocumentObject.ReturnAssetsFromLeasee2_4")
		Or DocumentType = Type("DocumentObject.ProvideAssetsToLeasee2_4") Then
			
		ThereIsChoiceOfAccounting = False;
		
	Else
		
		ThereIsChoiceOfAccounting = AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(
			Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate())));
			
	EndIf; 
	
	ThereIsChoiceTA = False;
	
	QueryText = 
	"SELECT
	|	Assets.Ref AS Ref,
	|	Assets.Presentation AS Presentation,
	|	&RecordInManAccounting AS RecordInManAccounting,
	|	&PostInAccounting AS PostInAccounting,
	|	&RecordInTA AS RecordInTA,
	|	ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) AS BUState,
	|	ISNULL(AccountingProcedureForOSBU.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_)) AS StateTa,
	|	ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) AS StateOfTheUU,
	|	FALocation.Organization AS LocationOrganization,	
	|	FALocation.Organization.Presentation AS LocationOrganizationPresentation,	
	|	FALocation.FixedAssetsLocation AS LocationDivision,
	|	FALocation.FixedAssetsLocation.Presentation AS LocationDivisionPresentation,
	|	FALocation.FinanciallyLiablePerson AS LocationOfPier,
	|	FALocation.FinanciallyLiablePerson.Presentation AS LocationOfPierPresentation 
	|FROM
	|	Catalog.Assets AS Assets
	|
	|		LEFT JOIN InformationRegister.FALocation.SliceLast(
	|				&Period,
	|				Recorder <> &Ref
	|					AND CorrectionDate = DATETIME(1,1,1)
	|					AND FixedAsset IN (&ListOfFA)) AS FALocation
	|		ON (FALocation.FixedAsset = Assets.Ref)
	|
	|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|				&Period,
	|				Recorder <> &Ref
	|					AND CorrectionDate = DATETIME(1,1,1)
	|					AND FixedAsset IN (&ListOfFA)) AS AccountingProcedureForOSBU
	|		ON (AccountingProcedureForOSBU.Organization = FALocation.Organization)
	|			AND (AccountingProcedureForOSBU.FixedAsset = FALocation.FixedAsset)
	|
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|				&Period,
	|				Recorder <> &Ref
	|					AND CorrectionDate = DATETIME(1,1,1)
	|					AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON (FixedAssetsAccountingProcedureManagementAccounting.Organization = FALocation.Organization)
	|			AND (FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = FALocation.FixedAsset)
	|WHERE
	|	Assets.Ref IN(&ListOfFA)
	|
	|	AND (&RecordInManAccounting AND &ThereIsChoiceOfAccounting
	|				AND NOT ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN (&StatesAccepted)
	|
	|			OR &PostInAccounting AND &ThereIsChoiceOfAccounting
	|				AND NOT ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN (&StatesAccepted)
	|
	|			OR &RecordInTA AND &ThereIsChoiceOfAccounting
	|				AND NOT ISNULL(AccountingProcedureForOSBU.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN (&StatesAccepted)
	|
	|			OR NOT ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN (&StatesAccepted)
	|				AND NOT ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN (&StatesAccepted)
	|				AND NOT ISNULL(AccountingProcedureForOSBU.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_)) IN (&StatesAccepted)
	|
	|			OR FALocation.Organization <> &Organization	
	|			OR FALocation.FixedAssetsLocation <> &Department
	|					AND &Department <> UNDEFINED
	|			OR FALocation.FinanciallyLiablePerson <> &FinanciallyLiablePerson 
	|					AND &FinanciallyLiablePerson <> UNDEFINED
	|	)";
		
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Period", Object.Date);
	Query.SetParameter("StatesAccepted", StatesAccepted);
	Query.SetParameter("ThereIsChoiceOfAccounting", ThereIsChoiceOfAccounting);
	
	If DocumentType = Type("DocumentObject.LeaseTermAdjustment")
		Or DocumentType = Type("DocumentObject.VendorInvoiceLeasedAssets") Then
			
		Query.SetParameter("RecordInManAccounting", True);
		Query.SetParameter("PostInAccounting", True);
		Query.SetParameter("RecordInTA", True);
		
	ElsIf ThereIsChoiceTA Then
			
		Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
		Query.SetParameter("PostInAccounting", Object.PostInAccounting);
		Query.SetParameter("RecordInTA", Object.RecordInTA);
		
	Else
				
		Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
		Query.SetParameter("PostInAccounting", Object.RecordInLocalAccounting);
		Query.SetParameter("RecordInTA", Object.RecordInLocalAccounting);
		
	EndIf;
	
	If DocumentType = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4") Then
		If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty 
			Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut Then
			NameOfPropsDivision = Undefined;
		Else
			NameOfPropsDivision = "FixedAssetsLocation";
		EndIf;
	ElsIf DocumentType = Type("DocumentObject.OBEntrySubAssetsAndComponentsOfDepreciation") Then
		NameOfPropsDivision = "FixedAssetsLocation";
	ElsIf DocumentType = Type("DocumentObject.ChangeFixedAssetFinancialDetails2_4")
		Or DocumentType = Type("DocumentObject.LeaseTermAdjustment")
		Or DocumentType = Type("DocumentObject.VendorInvoiceLeasedAssets") Then
		NameOfPropsDivision = Undefined;
	Else
		NameOfPropsDivision = "Department";
	EndIf;
	
	If NameOfPropsDivision <> Undefined Then
		Query.SetParameter("Department", Object[NameOfPropsDivision]);
	Else
		Query.SetParameter("Department", Undefined);
	EndIf;

	ThereArePropsTheySay = (DocumentType = Type("DocumentObject.FATransfer2_4"));
	If ThereArePropsTheySay Then
		Query.SetParameter("FINANCIALLYLIABLEPERSON", Object.FinanciallyLiablePerson);
	Else
		Query.SetParameter("FINANCIALLYLIABLEPERSON", Undefined);
	EndIf;

	MainToolInHeader = (DocumentType = Type("DocumentObject.SplitFixedAssets"));
	
	If DocumentType = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4")
		And (Object.BusinessOperation = Enums.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets
			Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut) Then
		TSName = "LeasedAsset";
	Else
		TSName = "FA";
	EndIf;
	
	MainToolInHeader = (DocumentType = Type("DocumentObject.SplitFixedAssets"));
	
	If MainToolInHeader Then
		Query.SetParameter("ListOfFA", Object.FixedAsset);
	ElsIf DocumentType = Type("DocumentObject.LeaseTermAdjustment") Then
		Query.SetParameter("ListOfFA", Documents.LeaseTermAdjustment.ListOfFASystemsToBeChecked(Object));
	Else
		Query.SetParameter("ListOfFA", Object[TSName].UnloadColumn("FixedAsset"));
	EndIf;
	
	ThisIsMovingNodes = DocumentType = Type("DocumentObject.FATransfer2_4")
		And Object.BusinessOperation = Enums.BusinessTransactions.TransferSubAssets;
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	Selection = Result.Select();
	
	While Selection.Next() Do
		
		If Not MainToolInHeader Then
			TabularSection = Object[TSName]; // TabularSection - 
			FieldNameFA = "FixedAsset";
			RowData = TabularSection.Find(Selection.Ref, FieldNameFA);
			If RowData = Undefined And ThisIsMovingNodes Then
				FieldNameFA = "FixedAssetOwner";
				RowData = TabularSection.Find(Selection.Ref, FieldNameFA);
			EndIf;
			Path = CommonClientServer.PathToTabularSection(TSName, RowData.LineNumber, FieldNameFA);
		EndIf; 
		
		ThereAreLocationErrors = False;
		
		If StatesAccepted.Find(Selection.BUState) <> Undefined
			Or StatesAccepted.Find(Selection.StateOfTheUU) <> Undefined Then
			
			If Selection.LocationOrganization <> Object.Organization Then
	
				ThereAreLocationErrors = True;
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" được liệt kê trong một doanh nghiệp khác ""%2"".';
									|ru = 'Основное средство ""%1"" числится в другой организации ""%2"".';
									|en = 'Fixed asset ""%1"" is in another company ""%2"".'; fa = 'Fixed asset ""%1"" is in another company ""%2"".';
									|it = 'Il Capitale fisso ""%1"" appartiene ad un''altra azienda ""%2"".';
									|pl = 'Środek trwały ""%1"" jest zapisany w innej firmie ""%2"".';
									|tr = '""%1"" sabit kıymeti başka bir ""%2"" iş yerinde listelenmektedir.'");
				MessageText = StrTemplate(MessageText, Selection.Presentation, Selection.LocationOrganizationPresentation);
				MessageToUser(MessageText, Object, MainToolInHeader, Path, Cancel); 
					
			EndIf;
			
			If NameOfPropsDivision <> Undefined
				And Selection.LocationDivision <> Object[NameOfPropsDivision] Then
	
				ThereAreLocationErrors = True;
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" được liệt kê trong bộ phận khác ""%2"".';
									|ru = 'Основное средство ""%1"" числится в другом подразделении ""%2"".';
									|en = 'Fixed asset ""%1"" is in another business unit ""%2"".'; fa = 'Fixed asset ""%1"" is in another business unit ""%2"".';
									|it = 'Il Capitale fisso ""%1"" appartiene ad un altro reparto ""%2"".';
									|pl = 'Środek trwały „%1” jest zapisany w innym dziale „%2”';
									|tr = 'Sabit kıymet ""%1"" başka bir kuruluş departmanında listelenir ""%2"".'");
				MessageText = StrTemplate(MessageText, Selection.Presentation, Selection.LocationDivisionPresentation);
				MessageToUser(MessageText, Object, MainToolInHeader, Path, Cancel); 
					
			EndIf;

			If ThereArePropsTheySay 
				And Selection.LocationOfPier <> Object.FinanciallyLiablePerson Then
	
				ThereAreLocationErrors = True;
				
				If ValueIsFilled(Selection.LocationOfPier) Then
					MessageText = NStr("vi = 'Tài sản cố định ""%1"" được gán cho một người chịu trách nhiệm ""%2"" khác.';
										|ru = 'Основное средство ""%1"" числится за другим МОЛ ""%2"".';
										|en = 'Fixed asset ""%1"" is registered with the other financially liable person ""%2"".'; fa = 'Fixed asset ""%1"" is registered with the other financially liable person ""%2"".';
										|it = 'Il Capitale fisso ""%1"" è registrato a carico di un''altra Persona Materialmente Responsabile ""%2"".';
										|pl = 'Środek trwały ""%1"" jest zapisany na inną osobę materialnie odpowiedzialną ""%2"".';
										|tr = '""%1"" sabit kıymeti başka bir sorumlu kişi ""%2"" için listelenir.'");
					MessageText = StrTemplate(MessageText, Selection.Presentation, Selection.LocationOfPierPresentation);
				Else
					MessageText = NStr("vi = 'Tài sản cố định ""%1"" không được liệt kê cho người chịu trách nhiệm';
										|ru = 'Основное средство ""%1"" не числится за МОЛ.';
										|en = 'Fixed asset ""%1"" is not registered with the financially liable person.'; fa = 'Fixed asset ""%1"" is not registered with the financially liable person.';
										|it = 'Il capitale fisso ""%1"" non è registrato a carico di nessuna Persona Materialmente Responsabile';
										|pl = 'Środek trwały ""%1"" nie jest zapisany na osobę materialnie odpowiedzialną.';
										|tr = 'Sabit kıymet ""%1"" sorumlu kişi için listelenmez.'");
					MessageText = StrTemplate(MessageText, Selection.Presentation);
				EndIf;

				MessageToUser(MessageText, Object, MainToolInHeader, Path, Cancel); 
					
			EndIf;

		EndIf;
				
		If Not ThereAreLocationErrors
			And Not DocumentType = Type("DocumentObject.VendorInvoiceLeasedAssets") Then
				
			// If the location is incorrect, then there is no point in reporting the condition.
			If ThereIsChoiceOfAccounting Then
				
				If Selection.RecordInManAccounting
					And StatesAccepted.Find(Selection.StateOfTheUU) = Undefined Then

					MessageText = NStr("vi = 'Tài sản cố định ""%1"" không được chấp nhận để hạch toán %2 trong kế toán quản trị.';
										|ru = 'Основное средство ""%1"" не принято к учету на %2 в управленческом учете.';
										|en = 'The ""%1"" fixed asset is not recognized in management accounting as of %2.'; fa = 'The ""%1"" fixed asset is not recognized in management accounting as of %2.';
										|it = 'Il capitale fisso ""%1"" non è registrato in contabilità in %2 nella contabilità gestionale.';
										|pl = 'Środek trwały ""%1"" nie jest przyjęty do ewidencji na %2 w ewidencji zarządczej.';
										|tr = 'Sabit kıymet ""%1"" yönetim muhasebesinde %2 dikkate alınmaz.'");
					MessageText = StrTemplate(MessageText, Selection.Presentation, Format(Object.Date, "DLF=D"));
					MessageToUser(MessageText, Object, MainToolInHeader, Path, Cancel); 
					
				EndIf;
				
				If ThereIsChoiceTA Then
					
					If Selection.PostInAccounting
						And StatesAccepted.Find(Selection.BUState) = Undefined Then
	
						MessageText = NStr("vi = 'Tài sản cố định ""%1"" không được chấp nhận để hạch toán %2 trong kế toán tài chính.';
											|ru = 'Основное средство ""%1"" не принято к учету на %2 в регламентированном учете.';
											|en = 'The ""%1"" fixed asset is not recognized in local accounting as of %2.'; fa = 'The ""%1"" fixed asset is not recognized in local accounting as of %2.';
											|it = 'Il capitale fisso ""%1"" non è registrato in contabilità in %2 nella contabilità regolatoria.';
											|pl = 'Środek trwały ""%1"" nie jest przyjęty do ewidencji na %2 w ewidencji reglamentowanej.';
											|tr = 'Sabit kıymet ""%1"" %2yerel muhasebede dikkate alınmaz.'");						
						MessageText = StrTemplate(MessageText, Selection.Presentation, Format(Object.Date, "DLF=D"));
						MessageToUser(MessageText, Object, MainToolInHeader, Path, Cancel); 
						
					EndIf;
				
					If Selection.RecordInTA
						And StatesAccepted.Find(Selection.StateTa) = Undefined Then
	
						MessageText = NStr("vi = 'Tài sản cố định ""%1"" không được chấp nhận để hạch toán %2 trong kế toán thuế.';
											|ru = 'Основное средство ""%1"" не принято к учету на %2 в налоговом учете.';
											|en = 'The ""%1"" fixed asset is not recognized in tax accounting as of %2.'; fa = 'The ""%1"" fixed asset is not recognized in tax accounting as of %2.';
											|it = 'Основное средство ""%1"" не принято к учету на %2 в налоговом учете.';
											|pl = 'The ""%1"" fixed asset is not recognized in tax accounting as of %2.';
											|tr = '""%1"" sabit kıymeti vergi muhasebesindeki %2 üzerinde muhasebeleştirilmemiştir.'");						
						MessageText = StrTemplate(MessageText, Selection.Presentation, Format(Object.Date, "DLF=D"));
						MessageToUser(MessageText, Object, MainToolInHeader, Path, Cancel); 
						
					EndIf;
				
				Else
					
					If Selection.PostInAccounting
						And StatesAccepted.Find(Selection.BUState) = Undefined
						And StatesAccepted.Find(Selection.StateTa) = Undefined Then
	
						MessageText = NStr("vi = 'Tài sản cố định ""%1"" không được chấp nhận để hạch toán %2 trong kế toán tài chính.';
											|ru = 'Основное средство ""%1"" не принято к учету на %2 в регламентированном учете.';
											|en = 'The ""%1"" fixed asset is not recognized in local accounting as of %2.'; fa = 'The ""%1"" fixed asset is not recognized in local accounting as of %2.';
											|it = 'Il capitale fisso ""%1"" non è registrato in contabilità in %2 nella contabilità regolatoria.';
											|pl = 'Środek trwały ""%1"" nie jest przyjęty do ewidencji na %2 w ewidencji reglamentowanej.';
											|tr = 'Sabit kıymet ""%1"" %2yerel muhasebede dikkate alınmaz.'");						
						MessageText = StrTemplate(MessageText, Selection.Presentation, Format(Object.Date, "DLF=D"));
						MessageToUser(MessageText, Object, MainToolInHeader, Path, Cancel); 
						
					EndIf;
					
				EndIf;
				
			ElsIf StatesAccepted.Find(Selection.BUState) = Undefined
				And StatesAccepted.Find(Selection.StateTa) = Undefined
				And StatesAccepted.Find(Selection.StateOfTheUU) = Undefined Then
				
				MessageText = NStr("vi = 'Tài sản cố định ""%1"" không được chấp nhận để chiếm %2.';
									|ru = 'Основное средство ""%1"" не принято к учету на %2.';
									|en = 'The ""%1"" fixed asset is not recognized as of %2.'; fa = 'The ""%1"" fixed asset is not recognized as of %2.';
									|it = 'Il capitale fisso ""%1"" non è registrato in contabilità in %2.';
									|pl = 'Środek trwały ""%1"" nie jest przyjęty do ewidencji na %2.';
									|tr = 'Sabit kıymet ""%1"" %2üzerinde dikkate alınmaz.'");
				MessageText = StrTemplate(MessageText, Selection.Presentation, Format(Object.Date, "DLF=D"));
				MessageToUser(MessageText, Object, MainToolInHeader, Path, Cancel); 
				
			EndIf; 
		
		EndIf;		
		
	EndDo;
	
EndProcedure

// Verifies that the OS is leased.
// 
// Parameters:
// 	Object - DocumentObject.FixedAssetCostAndDepreciationAdjustment - 
// 	Cancel - Boolean -
Procedure CheckThatFAIsLeasedForBalance(Object, Cancel) Export

	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date) Then
		// There is no need to check, because the document will be checked before the start date of accounting.
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	Assets.Ref AS Ref,
	|	Assets.Presentation AS Presentation
	|FROM
	|	Catalog.Assets AS Assets
	|		LEFT JOIN InformationRegister.LeasedAsset.SliceLast(&Period, Recorder <> &Ref AND FixedAsset IN (&ListOfFA)) AS LeasedAsset
	|		ON LeasedAsset.FixedAsset = Assets.Ref
	|			AND LeasedAsset.State = VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting)
	|WHERE
	|	Assets.Ref IN(&ListOfFA)
	|	AND LeasedAsset.FixedAsset IS NULL";
		
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Period", Object.Date);
	Query.SetParameter("ListOfFA", Object.FA.UnloadColumn("FixedAsset"));
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		MessageText = NStr("vi = 'Tài sản cố định ""%1"" không đưa vào thuê (kế toán ngoài bảng) đối với %2.';
							|ru = 'Основное средство ""%1"" не поступало в аренду (забалансовый учет) на %2.';
							|en = 'Fixed asset ""%1"" was not leased (off-balance accounting) at %2.'; fa = 'Fixed asset ""%1"" was not leased (off-balance accounting) at %2.';
							|it = 'L''immobilizzazione ""%1"" non è stata ricevuta in affitto (contabilità fuori bilancio) per %2.';
							|pl = 'Środek trwały ""%1"" nie wpłynął do dzierżawy (ewidencja pozabilansowa) na %2.';
							|tr = 'Sabit kıymet ""%1"" %2üzerinde kiralanmadı (bilanço dışı muhasebe).'");
		MessageText = StrTemplate(MessageText, Selection.Presentation, Format(Object.Date, "DLF=D"));
			
		RowData = Object.FA.Find(Selection.Ref, "FixedAsset");
		Path = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "FixedAsset");
		Common.MessageToUser(MessageText, Object, Path,, Cancel);
		
	EndDo;
	
EndProcedure

// Checks that the OS is not leased to the balance.
// 
// Parameters:
// 	Object - DocumentObject.DisposeFixedAssets2_4, DocumentObject.MergeOfFixedAssets, DocumentObject.SplitFixedAssets - 
// 	Cancel - Boolean -
Procedure CheckThatFAIsNotReceivedForRentOnBalance(Object, Cancel) Export
	
	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date) Then
		// There is no need to check, because the document will be checked before the start date of accounting.
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	LeasedAsset.FixedAsset AS Ref,
	|	LeasedAsset.FixedAsset.Presentation AS Presentation
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(&Period, Recorder <> &Ref AND FixedAsset IN (&ListOfFA)) AS LeasedAsset
	|WHERE
	|	LeasedAsset.State IN (
	|		VALUE(Enum.FixedAssetsStates.LeaseContractsSigned),
	|		VALUE(Enum.FixedAssetsStates.InLease))";
		
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Period", Object.Date);
	
	DataInHeader = (TypeOf(Object) = Type("DocumentObject.SplitFixedAssets"));
	
	If DataInHeader Then
		
		ListOfFA = New Array;
		ListOfFA.Add(Object.FixedAsset);
	
	Else
		
		ListOfFA = Object.FA.UnloadColumn("FixedAsset");
		
		If TypeOf(Object) = Type("DocumentObject.MergeOfFixedAssets")
			And Object.BusinessOperation = Enums.BusinessTransactions.AttachingToExistingFixedAsset
			And ValueIsFilled(Object.FixedAsset) Then
			ListOfFA.Add(Object.FixedAsset);
		EndIf;
		
	EndIf;
		
	Query.SetParameter("ListOfFA", ListOfFA);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		MessageText = NStr("vi = 'Không hỗ trợ lập chứng từ đối với tài sản cố định ""%1"" đã tiếp nhận vào thuê.';
							|ru = 'Оформление документа не поддерживается для основного средства ""%1"", поступившего в аренду.';
							|en = 'Document registration is not supported for leased fixed asset ""%1"".'; fa = 'Document registration is not supported for leased fixed asset ""%1"".';
							|it = 'La registrazione del documento non è supportata per l''immobilizzazione ""%1"" in ricezione in affitto.';
							|pl = 'Utworzenie dokumentu nie jest obsługiwane dla środka trwałego ""%1"", który wpłyną do dzierżawy.';
							|tr = 'Belgenin yürütülmesi, kiralanan sabit kıymet ""%1"" için desteklenmez.'");
		MessageText = StrTemplate(MessageText, Selection.Presentation);
		
		If DataInHeader Then
			Common.MessageToUser(MessageText, Object, "FixedAsset",, Cancel);
		Else
			RowData = Object.FA.Find(Selection.Ref, "FixedAsset");
			Path = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "FixedAsset");
			Common.MessageToUser(MessageText, Object, Path,, Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks that the FA has not been transferred to the FIN. rent.
// 
// Parameters:
// 	Object - DocumentObject.DisposeFixedAssets2_4, DocumentObject.PreparingForFixedAssetSale2_4, DocumentObject.SplitFixedAssets, DocumentObject.MergeOfFixedAssets, DocumentObject.FixedAssetsCostAdditions2_4 - 
// 	Cancel - Boolean -
Procedure CheckThatFAHasNotBeenTransferredToFinLease(Object, Cancel) Export
	
	If Not GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	AssetsLeasedOut.FixedAsset AS Ref,
	|	AssetsLeasedOut.FixedAsset.Presentation AS Presentation
	|FROM
	|	InformationRegister.AssetsLeasedOut.SliceLast(
	|		&Period, 
	|		Recorder <> &Ref 
	|			AND FixedAsset IN (&ListOfFA)) AS AssetsLeasedOut
	|
	|WHERE
	|	AssetsLeasedOut.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|	AND CAST(AssetsLeasedOut.Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfContractsUnderFSB25)
	|";
		
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Period", Object.Date);
	Query.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	
	DataInHeader = (TypeOf(Object) = Type("DocumentObject.SplitFixedAssets"));
	
	If DataInHeader Then
		
		ListOfFA = New Array;
		ListOfFA.Add(Object.FixedAsset);
	
	Else
		
		ListOfFA = Object.FA.UnloadColumn("FixedAsset");
		
		If TypeOf(Object) = Type("DocumentObject.MergeOfFixedAssets")
			And Object.BusinessOperation = Enums.BusinessTransactions.AttachingToExistingFixedAsset
			And ValueIsFilled(Object.FixedAsset) Then
			ListOfFA.Add(Object.FixedAsset);
		EndIf;
		
	EndIf;
		
	Query.SetParameter("ListOfFA", ListOfFA);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		MessageText = NStr("vi = 'Không hỗ trợ việc tạo chứng từ cho tài sản cố định ""%1"" được chuyển cho thuê.
							  |Trước khi tạo chứng từ, cần trả lại tài sản cố định đã thuê.';
							  |ru = 'Оформление документа не поддерживается для основного средства ""%1"" переданного в аренду.
							  |Перед оформлением документа, основное средство необходимо вернуть из аренды.';
							  |en = 'Cannot register the document for the %1 fixed asset provided to the lessee.
							  |Before you register the document, return the fixed asset from the lessee.'; fa = 'Cannot register the document for the %1 fixed asset provided to the lessee.
							  |Before you register the document, return the fixed asset from the lessee.';
							  |it = 'Оформление документа не поддерживается для основного средства ""%1"" переданного в аренду.
							  |Перед оформлением документа, основное средство необходимо вернуть из аренды.';
							  |pl = 'Cannot register the document for the %1 fixed asset provided to the lessee.
							  |Before you register the document, return the fixed asset from the lessee.';
							  |tr = 'Kiralanan ""%1"" sabit kıymeti için belge oluşturma desteklenmemektedir.
							  |Belge oluşturulmadan önce sabit kıymetin kiralamadan iade edilmesi gerekmektedir.'");
		MessageText = StrTemplate(MessageText, Selection.Presentation);
		
		If DataInHeader Then
			
			Common.MessageToUser(MessageText, Object, "FixedAsset",, Cancel);
			
		Else
			
			RowData = Object.FA.Find(Selection.Ref, "FixedAsset");
			If RowData <> Undefined Then
				
				Path = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "FixedAsset");
				Common.MessageToUser(MessageText, Object, Path,, Cancel);
			
			ElsIf TypeOf(Object) = Type("DocumentObject.MergeOfFixedAssets")
				And Object.BusinessOperation = Enums.BusinessTransactions.AttachingToExistingFixedAsset
				And Object.FixedAsset = Selection.Ref Then
					
				Common.MessageToUser(MessageText, Object, "FixedAsset",, Cancel);
				
			Else
				Common.MessageToUser(MessageText, Object,,, Cancel);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Verifies that fixed assets are accepted for accounting.
// 
// Parameters:
// 	Object - DocumentObject - 
// 	Cancel - Boolean -
// 
Procedure CheckThatIAAreAcceptedForAccounting(Object, Cancel) Export

	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date) Then
		// There is no need to check, because the document will be checked before the start date of accounting.
		Return;
	EndIf;
	
	DocumentType = TypeOf(Object);
	
	DocumentAttributes = New Structure("Organization,Department");
	FillPropertyValues(DocumentAttributes, Object);
	
	ThereIsChoiceTA = False;
	
	
	QueryText = NonCurrentAssetsLocalization.QueryTextCheckThatIAAreAcceptedForAccounting();
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	IntangibleAssets.Ref AS Ref,
		|	IntangibleAssets.Presentation AS Presentation,
		|	IntangibleAssets.KindOfAccountingObject AS KindOfAccountingObject,
		|	&RecordInManAccounting AS RecordInManAccounting,
		|	&PostInAccounting AS PostInAccounting,
		|	&RecordInTA AS RecordInTA,
		|	ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) AS BUState,
		|	ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) AS StateTa,
		|	ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) AS StateOfTheUU,
		|	IntangibleAssetsRegistrationPlace.Organization AS Organization,
		|	IntangibleAssetsRegistrationPlace.Organization.Presentation AS OrganizationPresentation,
		|	IntangibleAssetsRegistrationPlace.Department AS Department,
		|	IntangibleAssetsRegistrationPlace.Department.Presentation AS DepartmentPresentation
		|FROM
		|	Catalog.IntangibleAssets AS IntangibleAssets
		|
		|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
		|				&Period,
		|				Organization = &Organization
		|					AND Recorder <> &Ref
		|					AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetsAccountingProcedureManagementAccounting
		|		ON (IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset = IntangibleAssets.Ref)
		|
		|		LEFT JOIN InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
		|				&Period,
		|				Organization = &Organization
		|					AND Recorder <> &Ref
		|					AND IntangibleAsset IN (&ListOfIA)) AS IABookkeepingProcedureBookkeepingAndTaxAccounting
		|		ON (IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset = IntangibleAssets.Ref)
		|
		|		LEFT JOIN InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast(
		|				&Period,
		|				Recorder <> &Ref
		|					AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetsRegistrationPlace
		|		ON (IntangibleAssetsRegistrationPlace.IntangibleAsset = IntangibleAssets.Ref)
		|WHERE
		|	IntangibleAssets.Ref IN(&ListOfIA)
		|
		|	AND (&RecordInManAccounting
		|			AND NOT ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN (&StatesAccepted)
		|
		|		OR &PostInAccounting
		|			AND NOT ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN (&StatesAccepted)
		|
		|		OR NOT ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN (&StatesAccepted)
		|			AND NOT ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) IN (&StatesAccepted)
		|
		// Checking the place of registration of IA
		|		OR (
		|				(NOT &RecordInManAccounting OR ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, UNDEFINED) IN (&StatesAccepted))
		|				AND (ISNULL(IntangibleAssetsRegistrationPlace.Organization, UNDEFINED) <> &Organization
		|						AND &Organization <> VALUE(Catalog.Companies.EmptyRef)
		|					OR ISNULL(IntangibleAssetsRegistrationPlace.Department, UNDEFINED) <> &Department
		|						AND &Department <> VALUE(Catalog.BusinessStructure.EmptyRef))
		|			)
		|		)";
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfIA", Object.IA.UnloadColumn("IntangibleAsset"));
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Period", Object.Date);
	
	If ThereIsChoiceTA Then
			
		Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
		Query.SetParameter("PostInAccounting", Object.PostInAccounting);
		Query.SetParameter("RecordInTA", Object.RecordInTA);
		
	Else
				
		Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
		Query.SetParameter("PostInAccounting", Object.RecordInLocalAccounting);
		Query.SetParameter("RecordInTA", Object.RecordInLocalAccounting);
		
	EndIf;
	
	If DocumentType = Type("DocumentObject.ChangeIntangibleAssetFinancialDetails2_4") Then
		Query.SetParameter("Department", Catalogs.BusinessStructure.EmptyRef());
	ElsIf DocumentType = Type("DocumentObject.EntryOfCapitalAssetsBalance2_4") Then
		Query.SetParameter("Department", Object.FixedAssetsLocation);
	Else
		Query.SetParameter("Department", Object.Department);
	EndIf;
	
	StatesAccepted = New Array;
	StatesAccepted.Add(Enums.IntangibleAssetsStates.PostedInFinancialAccounting);
	Query.SetParameter("StatesAccepted", StatesAccepted);
	
	If DocumentType = Type("DocumentObject.IATransfer2_4")
		Or DocumentType = Type("DocumentObject.PreparingForIntangibleAssetSale2_4") Then
		ThereIsChoiceOfAccounting = False;
	Else
		ThereIsChoiceOfAccounting = AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(
			Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate())));
	EndIf; 
	Query.SetParameter("ThereIsChoiceOfAccounting", ThereIsChoiceOfAccounting);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	Selection = Result.Select();
	
	While Selection.Next() Do
	
		RowData = Object.IA.Find(Selection.Ref, "IntangibleAsset");
		
		Path = CommonClientServer.PathToTabularSection("IA", RowData.LineNumber, "IntangibleAsset");
		
		If ThereIsChoiceOfAccounting Then
			
			If Selection.RecordInManAccounting
				And StatesAccepted.Find(Selection.StateOfTheUU) = Undefined Then

				If Selection.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
					MessageText = NStr("vi = 'Chi phí Nghiên cứu và phát triển ""%1"" không được tính đến  %2 trong kế toán quản trị.';
										|ru = 'Расходы на НИОКР ""%1"" не приняты к учету на %2 в управленческом учете.';
										|en = '%1 R&D expenses are not recognized in management accounting as of %2.'; fa = '%1 R&D expenses are not recognized in management accounting as of %2.';
										|it = 'Le spese in Ricerca & Sviluppo ""%1"" non sono registrate in contabilità in %2 nella contabilità gestionale.';
										|pl = 'Rozchody na R&D ""%1"" nie są przyjęte do ewidencji na %2 w ewidencji zarządczej.';
										|tr = 'Ar-Ge harcamaları ""%1"" %2yerel muhasebede  dikkate alınmaz.'");
				Else
					MessageText = NStr("vi = 'Tài sản cố định vô hình ""%1"" không được chấp nhận để chiếm %2 trong kế toán quản trị.';
										|ru = 'Нематериальный актив ""%1"" не принят к учету на %2 в управленческом учете.';
										|en = 'The ""%1"" intangible asset is not recognized in management accounting as of %2.'; fa = 'The ""%1"" intangible asset is not recognized in management accounting as of %2.';
										|it = 'Il bene immateriale ""%1"" non è registrato in contabilità in %2 nella contabilità gestionale.';
										|pl = 'Wartość niematerialna ""%1"" nie jest przyjęta do ewidencji na %2 w ewidencji zarządczej.';
										|tr = 'Maddi olmayan duran varlık ""%1"" %2düzenlenmiş muhasebede dikkate alınmaz.'");
				EndIf; 
				MessageText = StrTemplate(MessageText, Selection.Presentation, Format(Object.Date, "DLF=D"));
				Common.MessageToUser(MessageText, Object, Path,, Cancel);
				
			EndIf;
			
			If ThereIsChoiceTA Then
				
				If Selection.PostInAccounting
					And StatesAccepted.Find(Selection.BUState) = Undefined Then

					If Selection.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
						MessageText = NStr("vi = 'Chi phí Nghiên cứu và phát triển ""%1"" không được tính cho %2 trong kế toán tài chính.';
											|ru = 'Расходы на НИОКР ""%1"" не приняты к учету на %2 в бухгалтерском учете.';
											|en = 'The ""%1"" R&D expenses are not recognized in local accounting as of %2.'; fa = 'The ""%1"" R&D expenses are not recognized in local accounting as of %2.';
											|it = 'Расходы на НИОКР ""%1"" не приняты к учету на %2 в бухгалтерском учете.';
											|pl = 'The ""%1"" R&D expenses are not recognized in local accounting as of %2.';
											|tr = '""%1"" Ar-Ge harcamaları muhasebe kayıtlarındaki %2 üzerinde muhasebeleştirilmemiştir.'");
					Else
						MessageText = NStr("vi = 'Tài sản cố định vô hình ""%1"" không được tiếp nhận vào %2 trong kế toán tài chính.';
											|ru = 'Нематериальный актив ""%1"" не принят к учету на %2 в регламентированном учете.';
											|en = 'The ""%1"" intangible asset is not recognized in local accounting as of %2.'; fa = 'The ""%1"" intangible asset is not recognized in local accounting as of %2.';
											|it = 'Il bene immateriale ""%1"" non è registrato in contabilità in %2 nella contabilità regolatoria.';
											|pl = 'Wartość niematerialna ""%1"" nie jest przyjęta do ewidencji na %2 w ewidencji reglamentowanej.';
											|tr = 'Maddi olmayan duran varlık ""%1"" %2düzenlenmiş muhasebede  dikkate alınmaz.'");
					EndIf; 
					MessageText = StrTemplate(MessageText, Selection.Presentation, Format(Object.Date, "DLF=D"));
					Common.MessageToUser(MessageText, Object, Path,, Cancel);
					
				EndIf;
			
				If Selection.RecordInTA
					And StatesAccepted.Find(Selection.StateTa) = Undefined Then

					If Selection.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
						MessageText = NStr("vi = 'Chi phí Nghiên cứu và phát triển ""%1"" không được tính cho %2 trong kế toán thuế.';
											|ru = 'Расходы на НИОКР ""%1"" не приняты к учету на %2 в налоговом учете.';
											|en = 'The ""%1"" R&D expenses are not recognized in tax accounting as of %2.'; fa = 'The ""%1"" R&D expenses are not recognized in tax accounting as of %2.';
											|it = 'Расходы на НИОКР ""%1"" не приняты к учету на %2 в налоговом учете.';
											|pl = 'The ""%1"" R&D expenses are not recognized in tax accounting as of %2.';
											|tr = '""%1"" Ar-Ge harcamaları vergi muhasebesindeki %2 üzerinde muhasebeleştirilmemiştir.'");
					Else
						MessageText = NStr("vi = 'Tài sản cố định vô hình ""%1"" không được tiếp nhận vào %2 trong kế toán thuế.';
											|ru = 'Нематериальный актив ""%1"" не принят к учету на %2 в налоговом учете.';
											|en = 'The ""%1"" intangible asset is not recognized in tax accounting as of %2.'; fa = 'The ""%1"" intangible asset is not recognized in tax accounting as of %2.';
											|it = 'Нематериальный актив ""%1"" не принят к учету на %2 в налоговом учете.';
											|pl = 'The ""%1"" intangible asset is not recognized in tax accounting as of %2.';
											|tr = '""%1"" maddi olmayan duran varlığı vergi muhasebesindeki %2 üzerinde muhasebeleştirilmemiştir.'");
					EndIf; 
					MessageText = StrTemplate(MessageText, Selection.Presentation, Format(Object.Date, "DLF=D"));
					Common.MessageToUser(MessageText, Object, Path,, Cancel);
					
				EndIf;
			
			Else
				
				If Selection.PostInAccounting
					And StatesAccepted.Find(Selection.BUState) = Undefined
					And StatesAccepted.Find(Selection.StateTa) = Undefined Then

					If Selection.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
						MessageText = NStr("vi = 'Chi phí Nghiên cứu và phát triển ""%1"" không được tính cho %2 trong kế toán tài chính.';
											|ru = 'Расходы на НИОКР ""%1"" не приняты к учету на %2 в регламентированном учете.';
											|en = '%1 R&D expenses are not recognized in local accounting as of %2.'; fa = '%1 R&D expenses are not recognized in local accounting as of %2.';
											|it = 'Le spese in Ricerca & Sviluppo ""%1"" non sono registrate in contabilità in %2 nella contabilità regolatoria.';
											|pl = 'Rozchody na R&D ""%1"" nie są przyjęte do ewidencji %2 w ewidencji reglamentowanej.';
											|tr = 'Ar-Ge harcamaları ""%1"" %2yerel muhasebede  dikkate alınmaz.'");
					Else
						MessageText = NStr("vi = 'Tài sản cố định vô hình ""%1"" không được tiếp nhận vào %2 trong kế toán tài chính.';
											|ru = 'Нематериальный актив ""%1"" не принят к учету на %2 в регламентированном учете.';
											|en = 'The ""%1"" intangible asset is not recognized in local accounting as of %2.'; fa = 'The ""%1"" intangible asset is not recognized in local accounting as of %2.';
											|it = 'Il bene immateriale ""%1"" non è registrato in contabilità in %2 nella contabilità regolatoria.';
											|pl = 'Wartość niematerialna ""%1"" nie jest przyjęta do ewidencji na %2 w ewidencji reglamentowanej.';
											|tr = 'Maddi olmayan duran varlık ""%1"" %2düzenlenmiş muhasebede  dikkate alınmaz.'");
					EndIf; 
					MessageText = StrTemplate(MessageText, Selection.Presentation, Format(Object.Date, "DLF=D"));
					Common.MessageToUser(MessageText, Object, Path,, Cancel);
					
				EndIf;
				
			EndIf;
			
		ElsIf StatesAccepted.Find(Selection.BUState) = Undefined
			And StatesAccepted.Find(Selection.StateTa) = Undefined
			And StatesAccepted.Find(Selection.StateOfTheUU) = Undefined Then
				
			If Selection.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
				MessageText = NStr("vi = 'Chi phí Nghiên cứu và phát triển ""%1"" không được tính đến  %2.';
									|ru = 'Расходы на НИОКР ""%1"" не приняты к учету на %2.';
									|en = '%1 R&D expenses are not recognized as of %2.'; fa = '%1 R&D expenses are not recognized as of %2.';
									|it = 'Le spese in Ricerca & Sviluppo ""%1"" non sono registrate in contabilità in %2.';
									|pl = 'Rozchody na R&D ""%1"" nie są przyjęte do ewidencji na %2.';
									|tr = 'Ar-Ge harcamaları ""%1"" için %2dikkate alınmaz.'");
			Else
				MessageText = NStr("vi = 'Tài sản cố định vô hình ""%1"" không được ghi nhận cho %2.';
									|ru = 'Нематериальный актив ""%1"" не принят к учету на %2.';
									|en = 'The ""%1"" intangible asset is recognized as of %2.'; fa = 'The ""%1"" intangible asset is recognized as of %2.';
									|it = 'Il bene immateriale ""%1"" non è registrato in contabilità in %2.';
									|pl = 'Wartość niematerialna ""%1"" nie jest przyjęta do ewidencji na %2.';
									|tr = 'Maddi olmayan duran varlık ""%1"" %2üzerinde dikkate alınmaz.'");
			EndIf; 
			
			MessageText = StrTemplate(MessageText, Selection.Presentation, Format(Object.Date, "DLF=D"));
			Common.MessageToUser(MessageText, Object, Path,, Cancel);
			
		EndIf;
			
		If StatesAccepted.Find(Selection.BUState) <> Undefined
			Or StatesAccepted.Find(Selection.StateTa) <> Undefined
			Or StatesAccepted.Find(Selection.StateOfTheUU) <> Undefined Then
			
			If Selection.Organization <> Object.Organization
				And ValueIsFilled(Object.Organization) Then
				
				If Selection.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
					MessageText = NStr("vi = 'Chi phí Nghiên cứu và phát triển ""%1"" được chấp nhận hạch toán ở một doanh nghiệp khác  %2.';
										|ru = 'Расходы на НИОКР ""%1"" приняты к учету в другой организации %2.';
										|en = '%1 R&D expenses are recognized in another company %2.'; fa = '%1 R&D expenses are recognized in another company %2.';
										|it = 'Le spese in Ricerca & Sviluppo ""%1"" sono registrate in contabilità presso un''altra azienda %2.';
										|pl = 'Rozchody na R&D ""%1"" są przyjęte do ewidencji w innej firmie %2.';
										|tr = '""%1"" Ar-Ge harcamaları başka bir %2 iş yerinde muhasebeleştirilmektedir.'");
				Else
					MessageText = NStr("vi = 'Tài sản cố định vô hình ""%1"" được chấp nhận để hạch toán trong một doanh nghiệp khác  %2.';
										|ru = 'Нематериальный актив ""%1"" принят к учету в другой организации %2.';
										|en = '%1 intangible asset is recognized in another company %2.'; fa = '%1 intangible asset is recognized in another company %2.';
										|it = 'Il bene immateriale ""%1"" è registrato in contabilità presso un''altra azienda %2.';
										|pl = 'Wartości niematerialne ""%1"" są przyjęte do ewidencji w innej firmie%2.';
										|tr = '""%1"" maddi olmayan varlığı başka bir %2 iş yerinde muhasebeleştirilmektedir.'");
				EndIf; 
				
				MessageText = StrTemplate(MessageText, Selection.Presentation, Selection.OrganizationPresentation);
				Common.MessageToUser(MessageText, Object, Path,, Cancel);
				
			EndIf; 
			
			If Selection.Department <> DocumentAttributes.Department
				And ValueIsFilled(DocumentAttributes.Department) Then
				
				If Selection.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
					MessageText = NStr("vi = 'Chi phí Nghiên cứu và phát triển ""%1"" được chấp nhận hạch toán ở bộ phận khác %2.';
										|ru = 'Расходы на НИОКР ""%1"" приняты к учету в другое подразделение %2.';
										|en = '%1 R&D expenses are recognized in another business unit %2.'; fa = '%1 R&D expenses are recognized in another business unit %2.';
										|it = 'Le spese in Ricerca & Sviluppo ""%1"" sono registrate in contabilità presso un altro reparto %2.';
										|pl = 'Rozchody na R&D ""%1"" są przyjęte do ewidencji w innym dziale%2.';
										|tr = 'Ar-Ge harcamaları ""%1"" başka bir  %2departmanda dikkate alınır.'");
				Else
					MessageText = NStr("vi = 'Tài sản cố định vô hình ""%1"" được chấp nhận để hạch toán ở bộ phận khác %2.';
										|ru = 'Нематериальный актив ""%1"" принят к учету в другое подразделение %2.';
										|en = '%1 intangible asset is recognized in another business unit %2.'; fa = '%1 intangible asset is recognized in another business unit %2.';
										|it = 'Il bene immateriale ""%1"" è registrato in contabilità presso un altro reparto %2.';
										|pl = 'Wartość niematerialna ""%1"" jest przyjęta do ewidencji w innym dziale%2.';
										|tr = 'Bir maddi olmayan duran varlık ""%1"" başka bir %2departmanda  dikkate alınır.'");
				EndIf; 
				
				MessageText = StrTemplate(MessageText, Selection.Presentation, Selection.DepartmentPresentation);
				Common.MessageToUser(MessageText, Object, Path,, Cancel);
				
			EndIf; 
			
		EndIf;	

	EndDo;
	
EndProcedure

Procedure CheckThatFAHaveBeenSelected(Object, TSName, FieldName, Cancel) Export
	
	AvailableFATypes = New Array;
	AvailableFATypes.Add(Enums.FATypes.Asset);
	AvailableFATypes.Add(Enums.FATypes.GroupFA);
	AvailableFATypes.Add(Enums.FATypes.CapitalExpenditureInLeasedAssets);

	CheckFAType(AvailableFATypes, Object, TSName, FieldName, Cancel);
	
EndProcedure

Procedure CheckThatComponentNodesAreSelected(Object, TSName, FieldName, Cancel) Export
	
	AvailableFATypes = New Array;
	AvailableFATypes.Add(Enums.FATypes.Node);
	AvailableFATypes.Add(Enums.FATypes.DepreciationComponent);

	CheckFAType(AvailableFATypes, Object, TSName, FieldName, Cancel);
	
EndProcedure

Procedure CheckThatNodesAreSelected(Object, TSName, FieldName, Cancel) Export
	
	AvailableFATypes = New Array;
	AvailableFATypes.Add(Enums.FATypes.Node);

	CheckFAType(AvailableFATypes, Object, TSName, FieldName, Cancel);
	
EndProcedure

Procedure CheckCreationOfDocumentBasedOnFAGroup(ListOfFA) Export

	QueryText =
	"SELECT TOP 1
	|	Assets.Ref
	|FROM
	|	Catalog.Assets AS Assets
	|WHERE
	|	Assets.Ref IN (&ListOfFA)
	|	AND Assets.IsFolder";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfFA", ListOfFA);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	If Not Result.IsEmpty() Then
		
		MessageText = NStr("vi = 'Không hỗ trợ tạo chứng từ dựa trên nhóm TSCĐ';
							|ru = 'Создание документа на основании группы ОС не поддерживается';
							|en = 'Cannot create the document based on a fixed asset group'; fa = 'Cannot create the document based on a fixed asset group';
							|it = 'Cannot create the document based on a fixed asset group';
							|pl = 'Cannot create the document based on a fixed asset group';
							|tr = 'Sabit kıymet grubu üzerinden belge oluşturulması desteklenmiyor'");
			
		Raise(MessageText);
		
	EndIf;
	
EndProcedure
 
#EndRegion

#Region DepreciationCalculation

Procedure AddAccountingParametersForNonCurrentAssets(Val CalculationParameters) Export

	CalculationParameters.Insert("AccountingProcedureForVNAAccordingToIntStandardsIsApplied", True);
	CalculationParameters.Insert("NotAccountingProcedureForVNAAccordingToIntStandardsIsApplied", False);

	NonCurrentAssetsLocalization.AddAccountingParametersForNonCurrentAssets(CalculationParameters);
	
EndProcedure

Function FieldTextActualUsefulLife(PeriodStartField) Export

	FieldText = 
	"((YEAR(&BegOfMonth) - YEAR(BEGINOFPERIOD(&PeriodStartField, MONTH))) * 12 
		|				+ MONTH(&BegOfMonth) 
		|				- MONTH(BEGINOFPERIOD(&PeriodStartField, MONTH)))";
	
	Return StrReplace(FieldText, "&PeriodStartField", PeriodStartField);
	
EndFunction
 
Procedure DestroyTemporaryTablesAfterRecordingDepreciationCalculation(TempTablesManager, CalculationParameters) Export
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, CalculationParameters.TablesToUse);
	
EndProcedure

// Generates the request text that receives data from the register
// 
// Parameters:
//  RegisterName - String - Register name
//  TableName - String - table name
//  AccountingObject - String - Accounting object
//  ListOfRequests - Array of String -
//  TableNameListOfAccountingObjects - String - Name of the table containing the list of objects
//  CalculatingFields - Structure, Undefined - Calculating fields
Procedure QueryTextDepreciationCalculationParameters(RegisterName, TableName, AccountingObject, ListOfRequests, TableNameListOfAccountingObjects = "", CalculatingFields = Undefined) Export

	If CalculatingFields = Undefined Then
		CalculatingFields = New Structure;
	EndIf;
	
	NonCurrentAssetsLocalization.QueryTextDepreciationCalculationParameters(RegisterName, TableName, AccountingObject, ListOfRequests, CalculatingFields);
	
	RegisterSupportsCorrection = RegisterSupportsCorrection(RegisterName);
	
	ListOfRequestsIsLocal = New Array;
	
	If RegisterSupportsCorrection Then
		
		QueryText =
		"SELECT
		|	MAX(RegisterTable.Period) AS Period,
		|	MAX(BEGINOFPERIOD(RegisterTable.Period, DAY)) AS PeriodStartOfDay,
		|	RegisterTable.OrganizationField_ AS Organization,
		|	RegisterTable.AccountingObjectField AS AccountingObject
		|
		|INTO RegisterData_SlicePeriod
		|
		|FROM
		|	RegisterTableSource AS RegisterTable
		|
		|WHERE
		|	RegisterTable.Period < &BegOfMonth
		|	AND RegisterTable.CorrectionDate <= &EndOfMonth
		|	AND RegisterTable.Active
		|	AND (RegisterTable.AccountingObjectField) IN
		|			(SELECT
		|				ListOfAccountingObjects.AccountingObjectField
		|			FROM
		|				ListOfAccountingObjects AS ListOfAccountingObjects)
		|
		|GROUP BY
		|	RegisterTable.OrganizationField_,
		|	RegisterTable.AccountingObjectField
		|
		|INDEX BY
		|	AccountingObject,
		|	Organization,
		|	PeriodStartOfDay
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(ISNULL(RegisterTable.CorrectionDate, DATETIME(1,1,1))) AS CorrectionDate,
		|
		|	CASE
		|		WHEN MAX(ISNULL(RegisterTable.CorrectionDate, DATETIME(1,1,1))) <> DATETIME(1,1,1)
		|			THEN BEGINOFPERIOD(RegisterData_SlicePeriod.Period, DAY)
		|		ELSE RegisterData_SlicePeriod.Period 
		|	END AS Period,
		|
		|	RegisterData_SlicePeriod.Organization AS Organization,
		|	RegisterData_SlicePeriod.AccountingObject AS AccountingObject
		|
		|INTO RegisterData_SliceCorrectionPeriod
		|
		|FROM
		|	RegisterData_SlicePeriod AS RegisterData_SlicePeriod
		|
		|		LEFT JOIN RegisterTableSource AS RegisterTable
		|		ON RegisterTable.Period = RegisterData_SlicePeriod.PeriodStartOfDay
		|			AND RegisterTable.OrganizationField_ = RegisterData_SlicePeriod.Organization
		|			AND RegisterTable.AccountingObjectField = RegisterData_SlicePeriod.AccountingObject
		|			AND RegisterTable.CorrectionDate <= &EndOfMonth
		|			AND RegisterTable.CorrectionDate <> DATETIME(1,1,1)
		|			AND RegisterTable.Active
		|
		|GROUP BY
		|	RegisterData_SlicePeriod.Period,
		|	RegisterData_SlicePeriod.Organization,
		|	RegisterData_SlicePeriod.AccountingObject
		|
		|INDEX BY
		|	AccountingObject,
		|	Organization,
		|	Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(RegisterTable.Recorder) AS Recorder,
		|	RegisterData_SliceCorrectionPeriod.Period AS Period,
		|	RegisterData_SliceCorrectionPeriod.Organization AS Organization,
		|	RegisterData_SliceCorrectionPeriod.AccountingObject AS AccountingObject
		|
		|INTO RegisterData_SliceLogger
		|
		|FROM
		|	RegisterData_SliceCorrectionPeriod AS RegisterData_SliceCorrectionPeriod
		|
		|		INNER JOIN RegisterTableSource AS RegisterTable
		|		ON RegisterTable.OrganizationField_ = RegisterData_SliceCorrectionPeriod.Organization
		|			AND RegisterTable.AccountingObjectField = RegisterData_SliceCorrectionPeriod.AccountingObject
		|			AND RegisterTable.Period = RegisterData_SliceCorrectionPeriod.Period
		|			AND RegisterTable.CorrectionDate = RegisterData_SliceCorrectionPeriod.CorrectionDate
		|			AND RegisterTable.Active
		|
		|GROUP BY
		|	RegisterData_SliceCorrectionPeriod.Period,
		|	RegisterData_SliceCorrectionPeriod.Organization,
		|	RegisterData_SliceCorrectionPeriod.AccountingObject
		|
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&BegOfMonth AS BegOfMonth,
		|	&EndOfPreviousMonth AS ParameterPeriod,
		|	RegisterTable.OrganizationField_ AS Organization,
		|	RegisterTable.AccountingObjectField AS AccountingObjectField,
		|
		|	&FieldTexts
		|
		|INTO RegisterTable_SectionOfRecent
		|
		|FROM
		|	RegisterData_SliceLogger AS RegisterData_SliceLogger
		|
		|		INNER JOIN RegisterTableSource AS RegisterTable
		|		ON RegisterTable.Recorder = RegisterData_SliceLogger.Recorder
		|			AND RegisterTable.Period = RegisterData_SliceLogger.Period
		|			AND RegisterTable.OrganizationField_ = RegisterData_SliceLogger.Organization
		|			AND RegisterTable.AccountingObjectField = RegisterData_SliceLogger.AccountingObject
		|			AND RegisterTable.Active
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP RegisterData_SlicePeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP RegisterData_SliceCorrectionPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP RegisterData_SliceLogger
		|";
		
		ListOfRequestsIsLocal.Add(QueryText);
		
	Else
		
		QueryText =
		"SELECT
		|	&BegOfMonth AS BegOfMonth,
		|	&EndOfPreviousMonth AS ParameterPeriod,
		|	RegisterTable.OrganizationField_ AS Organization,
		|	RegisterTable.AccountingObjectField AS AccountingObjectField,
		|
		|	&FieldTexts
		|
		|INTO RegisterTable_SectionOfRecent
		|
		|FROM
		|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
		|		&EndOfPreviousMonth,
		|		(AccountingObjectField) IN
		|			(SELECT
		|				ListOfAccountingObjects.AccountingObjectField
		|			FROM
		|				ListOfAccountingObjects AS ListOfAccountingObjects)) AS RegisterTable
		|";
		
		ListOfRequestsIsLocal.Add(QueryText);
		
	EndIf;
	
	QueryText =
	"SELECT
	|	RegisterTable.BegOfMonth AS BegOfMonth,
	|	RegisterTable.ParameterPeriod AS ParameterPeriod,
	|	RegisterTable.Organization AS Organization,
	|	RegisterTable.AccountingObjectField AS AccountingObjectField,
	|
	|	&FieldTexts
	|
	|INTO TT_RegisterName
	|
	|FROM
	|	RegisterTable_SectionOfRecent AS RegisterTable
	|
	|UNION ALL
	|
	|SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	BEGINOFPERIOD(RegisterTable.Period, DAY) AS ParameterPeriod,
	|	RegisterTable.OrganizationField_ AS Organization,
	|	RegisterTable.AccountingObjectField AS AccountingObjectField,
	|
	|	&FieldTexts
	|
	|FROM
	|	RegisterTableSource AS RegisterTable
	|
	|WHERE
	|	RegisterTable.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND RegisterTable.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterTable.Active
	|
	|	AND VALUETYPE(RegisterTable.Recorder) IN (&TypeAcceptanceForAccounting)
	|
	|	AND (RegisterTable.AccountingObjectField) IN
	|			(SELECT
	|				ListOfAccountingObjects.AccountingObjectField
	|			FROM
	|				ListOfAccountingItemsFromDateOfAcceptanceForAccounting AS ListOfAccountingObjects)
	|
	|UNION ALL
	|
	|SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	BEGINOFPERIOD(RegisterTable.Period, DAY) AS ParameterPeriod,
	|	RegisterTable.OrganizationField_ AS Organization,
	|	RegisterTable.AccountingObjectField AS AccountingObjectField,
	|
	|	&FieldTexts
	|
	|FROM
	|	RegisterTableSource AS RegisterTable
	|
	|		LEFT JOIN Document.SplitFixedAssets AS SplitFixedAssets
	|		ON (SplitFixedAssets.Ref = RegisterTable.Recorder)
	|
	|WHERE
	|	RegisterTable.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND RegisterTable.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterTable.Active
	|
	|	AND VALUETYPE(RegisterTable.Recorder) = TYPE(Document.SplitFixedAssets)
	|	AND RegisterTable.AccountingObjectField <> SplitFixedAssets.FixedAsset
	|
	|	AND (RegisterTable.AccountingObjectField) IN
	|			(SELECT
	|				ListOfAccountingObjects.AccountingObjectField
	|			FROM
	|				ListOfAccountingItemsFromDateOfAcceptanceForAccounting AS ListOfAccountingObjects)
	|
	|UNION ALL
	|
	|SELECT
	|	&BegOfMonth AS BegOfMonth,
	|	BEGINOFPERIOD(RegisterTable.Period, DAY) AS ParameterPeriod,
	|	RegisterTable.OrganizationField_ AS Organization,
	|	RegisterTable.AccountingObjectField AS AccountingObjectField,
	|
	|	&FieldTexts
	|
	|FROM
	|	RegisterTableSource AS RegisterTable
	|
	|		LEFT JOIN Document.MergeOfFixedAssets AS MergeOfFixedAssets
	|		ON (MergeOfFixedAssets.Ref = RegisterTable.Recorder)
	|
	|WHERE
	|	RegisterTable.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND RegisterTable.CorrectionDate = DATETIME(1,1,1)
	|	AND RegisterTable.Active
	|
	|	AND VALUETYPE(RegisterTable.Recorder) = TYPE(Document.MergeOfFixedAssets)
	|	AND RegisterTable.AccountingObjectField = MergeOfFixedAssets.FixedAsset
	|	AND MergeOfFixedAssets.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
	|
	|	AND (RegisterTable.AccountingObjectField) IN
	|			(SELECT
	|				ListOfAccountingObjects.AccountingObjectField
	|			FROM
	|				ListOfAccountingItemsFromDateOfAcceptanceForAccounting AS ListOfAccountingObjects)
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginningOfPreviousMonth AS BegOfMonth,
	|	BEGINOFPERIOD(RegisterTable.Period, DAY) AS ParameterPeriod,
	|	RegisterTable.OrganizationField_ AS Organization,
	|	RegisterTable.AccountingObjectField AS AccountingObjectField,
	|
	|	&FieldTexts
	|
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(RegisterTable.Period, DAY) AS Period,
	|		MAX(RegisterTable.Recorder) AS Recorder,
	|		RegisterTable.OrganizationField_ AS Organization,
	|		RegisterTable.AccountingObjectField AS AccountingObjectField
	|
	|	FROM
	|		RegisterTableSource AS RegisterTable
	|
	|	WHERE
	|		RegisterTable.Period BETWEEN &BeginningOfPreviousMonth AND &EndOfPreviousMonth
	|		AND RegisterTable.CorrectionDate = DATETIME(1,1,1)
	|		AND RegisterTable.Active
	|
	|		AND VALUETYPE(RegisterTable.Recorder) IN (&TypeOfDocumentsForAdditionalCharges)
	|
	|		AND (RegisterTable.AccountingObjectField) IN
	|				(SELECT
	|					ListOfAccountingObjects.AccountingObjectField
	|				FROM
	|					ListOfAccountingItems_AdditionalCharges_All AS ListOfAccountingObjects)
	|
	|	GROUP BY
	|		BEGINOFPERIOD(RegisterTable.Period, DAY),
	|		RegisterTable.OrganizationField_,
	|		RegisterTable.AccountingObjectField
	|
	|	) AS RegisterTable_Slice
	|
	|		INNER JOIN RegisterTableSource AS RegisterTable
	|		ON RegisterTable.Recorder = RegisterTable_Slice.Recorder
	|			AND BEGINOFPERIOD(RegisterTable.Period, DAY) = RegisterTable_Slice.Period
	|			AND RegisterTable.OrganizationField_ = RegisterTable_Slice.Organization
	|			AND RegisterTable.AccountingObjectField = RegisterTable_Slice.AccountingObjectField
	|			AND RegisterTable.CorrectionDate = DATETIME(1,1,1)
	|			AND RegisterTable.Active
	|
	|INDEX BY
	|	AccountingObjectField,
	|	Organization,
	|	BegOfMonth,
	|	ParameterPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RegisterTable_SectionOfRecent
	|";
	ListOfRequestsIsLocal.Add(QueryText);
	
	QueryText = StrConcat(ListOfRequestsIsLocal, Common.QueryBatchSeparator());
	
	DonTAddFields = New Array;
	DonTAddFields.Add(Upper(AccountingObject));
	DonTAddFields.Add(Upper("Organization"));
	
	FieldTexts = CaseFieldText(RegisterName, CalculatingFields, DonTAddFields);
	
	If ThereIsCompanyInRegister(RegisterName) Then
		QueryText = StrReplace(QueryText, "(AccountingObjectField)", "(AccountingObjectField, Organization)");
		QueryText = StrReplace(QueryText, "(RegisterTable.AccountingObjectField)", "(RegisterTable.AccountingObjectField, RegisterTable.Organization)");
		QueryText = StrReplace(QueryText, "ListOfAccountingObjects.AccountingObjectField", "ListOfAccountingObjects.AccountingObjectField, ListOfAccountingObjects.Organization");
		QueryText = StrReplace(QueryText, "RegisterTable.OrganizationField_", "RegisterTable.Organization");
	Else
		QueryText = StrReplace(QueryText, "RegisterTable.OrganizationField_", "UNDEFINED");
	EndIf; 
	
	QueryText = StrReplace(QueryText, "AccountingObjectField", AccountingObject);
	QueryText = StrReplace(QueryText, "InformationRegister.FixedAssetsAccountingProcedure", "InformationRegister." + RegisterName);
	QueryText = StrReplace(QueryText, "RegisterTableSource", "InformationRegister." + RegisterName);
	QueryText = StrReplace(QueryText, "&FieldTexts", FieldTexts);
	QueryText = StrReplace(QueryText, "TT_RegisterName", ?(TableName <> "", TableName, RegisterName));

	If Not RegisterSupportsCorrection Then
		QueryText = StrReplace(QueryText, "RegisterTable.CorrectionDate = DATETIME(1,1,1)", "TRUE");
		QueryText = StrReplace(QueryText, "CorrectionDate = DATETIME(1,1,1)", "TRUE");
	EndIf;
	
	If ValueIsFilled(TableNameListOfAccountingObjects) Then
		QueryText = StrReplace(QueryText, "ListOfAccountingObjects", TableNameListOfAccountingObjects);
	EndIf;

	ListOfRequests.Add(QueryText);
	
EndProcedure

// Generates the request text that reflects the accrued depreciation in the other Expenses register.
// Used in documents that can accrue depreciation.
// 
// Parameters:
//	Add_Fields - String -
//	
// Returns:
//  String - query text.
//
Function RequestTextTableReflectionOfAccruedDepreciationInOtherExpenses(Add_Fields = "") Export

	QueryText = NonCurrentAssetsLocalization.RequestTextTableReflectionOfAccruedDepreciationInOtherExpenses(Add_Fields);
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	TableExpenses.CalculationPeriod                      AS Period,
		|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
		|	TableExpenses.Organization                        AS Organization,
		|	TableExpenses.DebitBusinessUnit                   AS Department,
		|	TableExpenses.ExpenseItem                     AS ExpenseItem,
		|	TableExpenses.DimensionOfExpenses                  AS DimensionOfExpenses,
		|	TableExpenses.CorLineOfBusiness         AS LineOfBusiness,
		|	UNDEFINED                                      AS VATActivityType,
		|	TableExpenses.AmountOfUU                            AS AmountIncludingVAT,
		|	TableExpenses.AmountOfUU                            AS AmountExcludingVAT,
		|	TableExpenses.AmountOfUU                            AS AmountExcludingVATMan,
		|	TableExpenses.AmountAccounting                            AS AmountIncludingVATCompl,
		|	TableExpenses.AmountAccounting                            AS AmountExcludingVATCompl,
		|	0                                                 AS PermanentDifference,
		|	0                                                 AS CostTD,
		|
		|	CASE 
		|		WHEN TableExpenses.TransferExpensesToAnotherCompany
		|				AND TableExpenses.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
		|			THEN CASE
		|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
		|						THEN VALUE(Enum.BusinessTransactions.FixedAssetsDepreciationChargeFromAnotherCompany)
		|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
		|						THEN VALUE(Enum.BusinessTransactions.IntangibleAssetsAmortizationChargeFromAnotherCompany)
		|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
		|						THEN VALUE(Enum.BusinessTransactions.RecogniseAsRDExpensesFromAnotherCompany)
		|				END
		|
		|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
		|			THEN VALUE(Enum.BusinessTransactions.FixedAssetsDepreciationCharge)
		|
		|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
		|			THEN VALUE(Enum.BusinessTransactions.IntangibleAssetsAmortizationCharge)
		|
		|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
		|			THEN VALUE(Enum.BusinessTransactions.RecogniseAsRDExpenses)
		|
		|	END AS BusinessOperation,
		|
		|	UNDEFINED AS ItemsLocationAttributes,
		|	
		|	TableExpenses.RowID AS FinRecordID,
		|
		|	CASE 
		|		WHEN TableExpenses.TransferExpensesToAnotherCompany
		|				AND TableExpenses.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
		|			THEN CASE
		|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
		|						THEN VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsDepreciationChargeFromAnotherCompany)
		|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
		|						THEN VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsAmortizationChargeFromAnotherCompany)
		|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
		|						THEN VALUE(Catalog.BusinessTransactionsSettings.RecogniseAsRDExpensesFromAnotherCompany)
		|				END
		|
		|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsDepreciationCharge)
		|
		|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsAmortizationCharge)
		|
		|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.RecogniseAsRDExpenses)
		|
		|	END AS BusinessTransactionSetting,
		|
		|	DocumentData.Ref AS Recorder,
		| 
		|	CASE
		|		WHEN TableExpenses.ThisIsAdjustmentOfDepreciationForPreviousPeriod
		|			THEN TableExpenses.AccrualPeriod
		|		ELSE DATETIME(1,1,1)
		|	END AS VariancePeriod
		|
		|	,&AdditionalFields
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN AccruedDepreciation AS TableExpenses
		|		ON TableExpenses.Organization = DocumentData.Organization
		|			AND TableExpenses.PackageNumber = DocumentData.PackageNumber
		|
		|WHERE
		|	NOT TableExpenses.AccrueDepreciation
		|	AND (TableExpenses.AmountOfUU <> 0
		|		OR TableExpenses.AmountAccounting <> 0)
		|";
		
		ReplaceAdditionalFieldsInRequest(QueryText, Add_Fields, "Recorder,VariancePeriod");
		
	EndIf;
	
	Return QueryText;

EndFunction

// Generates a request text reflecting the accrued depreciation in the batch register of other expenses.
// It is used in documents that can accrue depreciation.
// 
// Returns:
//  String - query text.
//
Function RequestTextTableReflectionOfAccruedDepreciationInBatchesOfOtherExpenses() Export
	
	QueryText = 
	"SELECT
	|	DocumentData.Period                                      AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                      AS RecordType,
	|	CASE
	|		WHEN TableExpenses.TransferExpensesToAnotherCompany
	|			THEN TableExpenses.CompanyRecipientOfExpenses
	|		ELSE TableExpenses.Organization
	|	END                                                       AS Organization,
	|	TableExpenses.DebitBusinessUnit                             AS Department,
	|	TableExpenses.ExpenseItem                               AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses                            AS DimensionOfExpenses,
	|	UNDEFINED                                                AS AssetsLiabilitiesDimension,
	|	DocumentData.Ref                                      AS ExpenseReceiptDocument,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	TableExpenses.CorLineOfBusiness                   AS LineOfBusiness,
	|	UNDEFINED                                                AS ItemsLocationAttributes,
	|	UNDEFINED                                                AS VATActivityType,
	|
	|	TableExpenses.AmountOfUU                                      AS Cost,
	|	TableExpenses.AmountOfUU                                      AS CostExcludingVAT,
	|	0                                                           AS VATManag,
	|	TableExpenses.AmountAccounting + TableExpenses.CFAmount             AS LocalCost,
	|	0                                                           AS VATLocal,
	|	TableExpenses.AmountPermanentDifferences + TableExpenses.PRCFAmount           AS PermanentDifference,
	|	TableExpenses.AmountTemporaryDifferences + TableExpenses.AmountOfVRCF           AS CostTD,
	|
	|	CASE 
	|		WHEN TableExpenses.TransferExpensesToAnotherCompany
	|				AND TableExpenses.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN CASE
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|						THEN VALUE(Enum.BusinessTransactions.FixedAssetsDepreciationChargeFromAnotherCompany)
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|						THEN VALUE(Enum.BusinessTransactions.IntangibleAssetsAmortizationChargeFromAnotherCompany)
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|						THEN VALUE(Enum.BusinessTransactions.RecogniseAsRDExpensesFromAnotherCompany)
	|				END
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|			THEN VALUE(Enum.BusinessTransactions.FixedAssetsDepreciationCharge)
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|			THEN VALUE(Enum.BusinessTransactions.IntangibleAssetsAmortizationCharge)
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|			THEN VALUE(Enum.BusinessTransactions.RecogniseAsRDExpenses)
	|
	|	END AS BusinessOperation,
	|	
	|	TableExpenses.RowID AS FinRecordID,
	|
	|	CASE 
	|		WHEN TableExpenses.TransferExpensesToAnotherCompany
	|				AND TableExpenses.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN CASE
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsDepreciationChargeFromAnotherCompany)
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsAmortizationChargeFromAnotherCompany)
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.RecogniseAsRDExpensesFromAnotherCompany)
	|				END
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsDepreciationCharge)
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsAmortizationCharge)
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.RecogniseAsRDExpenses)
	|
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS TableExpenses
	|		ON TableExpenses.Organization = DocumentData.Organization
	|			AND TableExpenses.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	NOT TableExpenses.AccrueDepreciation
	|
	|	AND (TableExpenses.AmountOfUU <> 0
	|		OR TableExpenses.AmountAccounting <> 0
	|		OR TableExpenses.AmountFA <> 0
	|		OR TableExpenses.AmountPermanentDifferences <> 0
	|		OR TableExpenses.AmountTemporaryDifferences <> 0
	|		OR TableExpenses.CFAmount <> 0
	|		OR TableExpenses.SumOfNUCF <> 0
	|		OR TableExpenses.PRCFAmount <> 0
	|		OR TableExpenses.AmountOfVRCF <> 0)
	|";
	
	Return QueryText;
	
EndFunction

// Generates a request text reflecting the depreciation in the Other Expenses register.
// It is used in documents that can accrue depreciation.
// 
// Parameters:
//  AdditionalFields - String - List of additional fields.
//  
// Returns:
//  String - query text.
//
Function RequestTextTableRecognitionOfImpairmentInOtherExpenses(AdditionalFields = "") Export
	
	#Region ReverseImpairment // Dt Expenses - Ct Impairment (reverse)
	QueryText = 
	"SELECT
	|	TableExpenses.CalculationPeriod                      AS Period,
	|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
	|	TableExpenses.Organization                        AS Organization,
	|	TableExpenses.DebitBusinessUnit                   AS Department,
	|	TableExpenses.ExpenseItem                     AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses                  AS DimensionOfExpenses,
	|	TableExpenses.CorLineOfBusiness         AS LineOfBusiness,
	|	UNDEFINED                                      AS VATActivityType,
	|
	|	-TableExpenses.ImpairmentMA                     AS AmountIncludingVAT,
	|	-TableExpenses.ImpairmentMA                     AS AmountExcludingVAT,
	|	-TableExpenses.ImpairmentMA                     AS AmountExcludingVATMan,
	|	-(TableExpenses.ImpairmentAC + TableExpenses.ImpairmentOfCF)   AS AmountIncludingVATCompl,
	|	-(TableExpenses.ImpairmentAC + TableExpenses.ImpairmentOfCF)   AS AmountExcludingVATCompl,
	|	0                                                 AS PermanentDifference,
	|	-(TableExpenses.ImpairmentAC + TableExpenses.ImpairmentOfCF)   AS CostTD,
	|
	|	CASE 
	|		WHEN TableExpenses.TransferExpensesToAnotherCompany
	|				AND TableExpenses.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN CASE
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|						THEN VALUE(Enum.BusinessTransactions.ReverseFAImpairmentFromAnotherCompany)
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|						THEN VALUE(Enum.BusinessTransactions.ReverseImpairmentOfIAFromAnotherCompany)
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|						THEN VALUE(Enum.BusinessTransactions.ReverseRAndDImpairmentFromAnotherCompany)
	|				END
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|			THEN VALUE(Enum.BusinessTransactions.ReverseFAImpairment)
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|			THEN VALUE(Enum.BusinessTransactions.ReverseImpairmentOfIA)
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|			THEN VALUE(Enum.BusinessTransactions.ReverseRAndDImpairment)
	|
	|	END AS BusinessOperation,
	|
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	TableExpenses.RowID AS FinRecordID,
	|
	|	CASE 
	|		WHEN TableExpenses.TransferExpensesToAnotherCompany
	|				AND TableExpenses.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN CASE
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseFAImpairmentFromAnotherCompany)
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseImpairmentOfIAFromAnotherCompany)
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseRAndDImpairmentFromAnotherCompany)
	|				END
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseFAImpairment)
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseImpairmentOfIA)
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseRAndDImpairment)
	|
	|	END AS BusinessTransactionSetting,
	|
	|	DocumentData.Ref                       AS Recorder,
	|	DATETIME(1,1,1)                             AS VariancePeriod
	|
	|	,&AdditionalFields
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS TableExpenses
	|		ON TableExpenses.Organization = DocumentData.Organization
	|			AND TableExpenses.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	TableExpenses.PostingOptionForImpairedFADepreciation = &ReverseImpairmentAdjustment
	|
	|	AND (TableExpenses.ImpairmentMA <> 0
	|		OR TableExpenses.ImpairmentAC <> 0
	|		OR TableExpenses.ImpairmentOfCF <> 0)
	|";
	#EndRegion
	
	ReplaceAdditionalFieldsInRequest(QueryText, AdditionalFields, "Recorder,VariancePeriod");	

	Return QueryText;
	
EndFunction

// Generates the text of the request reflecting the depreciation in the register of lots and other expenses.
// It is used in documents that can accrue depreciation.
// 
// Returns:
//  String - query text.
//
Function RequestTextTableRecognitionOfImpairmentInLotsOtherExpenses() Export
	
	#Region ReverseImpairment // Dt Expenses - Ct Impairment (reverse)
	QueryText =
	"SELECT
	|	DocumentData.Period                                      AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                      AS RecordType,
	|	CASE
	|		WHEN TableExpenses.TransferExpensesToAnotherCompany
	|			THEN TableExpenses.CompanyRecipientOfExpenses
	|		ELSE TableExpenses.Organization
	|	END                                                       AS Organization,
	|	TableExpenses.DebitBusinessUnit                             AS Department,
	|	TableExpenses.ExpenseItem                               AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses                            AS DimensionOfExpenses,
	|	UNDEFINED                                                AS AssetsLiabilitiesDimension,
	|	DocumentData.Ref                                      AS ExpenseReceiptDocument,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	TableExpenses.CorLineOfBusiness                   AS LineOfBusiness,
	|	UNDEFINED                                                AS ItemsLocationAttributes,
	|	UNDEFINED                                                AS VATActivityType,
	|
	|	-TableExpenses.ImpairmentMA                               AS Cost,
	|	-TableExpenses.ImpairmentMA                               AS CostExcludingVAT,
	|	0                                                           AS VATManag,
	|	-(TableExpenses.ImpairmentAC + TableExpenses.ImpairmentOfCF) AS LocalCost,
	|	0                                                           AS VATLocal,
	|	0                                                           AS PermanentDifference,
	|	-(TableExpenses.ImpairmentAC + TableExpenses.ImpairmentOfCF) AS CostTD,
	|
	|	CASE 
	|		WHEN TableExpenses.TransferExpensesToAnotherCompany
	|				AND TableExpenses.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN CASE
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|						THEN VALUE(Enum.BusinessTransactions.ReverseFAImpairmentFromAnotherCompany)
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|						THEN VALUE(Enum.BusinessTransactions.ReverseImpairmentOfIAFromAnotherCompany)
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|						THEN VALUE(Enum.BusinessTransactions.ReverseRAndDImpairmentFromAnotherCompany)
	|				END
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|			THEN VALUE(Enum.BusinessTransactions.ReverseFAImpairment)
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|			THEN VALUE(Enum.BusinessTransactions.ReverseImpairmentOfIA)
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|			THEN VALUE(Enum.BusinessTransactions.ReverseRAndDImpairment)
	|
	|	END AS BusinessOperation,
	|	
	|	TableExpenses.RowID AS FinRecordID,
	|
	|	CASE 
	|		WHEN TableExpenses.TransferExpensesToAnotherCompany
	|				AND TableExpenses.CompanyRecipientOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN CASE
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseFAImpairmentFromAnotherCompany)
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseImpairmentOfIAFromAnotherCompany)
	|					WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseRAndDImpairmentFromAnotherCompany)
	|				END
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseFAImpairment)
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.IA)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseImpairmentOfIA)
	|
	|		WHEN TableExpenses.VNAView = VALUE(Enum.KindsOfNonCurrentAssets.RD)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseRAndDImpairment)
	|
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN AccruedDepreciation AS TableExpenses
	|		ON TableExpenses.Organization = DocumentData.Organization
	|			AND TableExpenses.PackageNumber = DocumentData.PackageNumber
	|
	|WHERE
	|	NOT TableExpenses.AccrueDepreciation
	|	AND TableExpenses.PostingOptionForImpairedFADepreciation = &ReverseImpairmentAdjustment
	|
	|	AND (TableExpenses.ImpairmentMA <> 0
	|		OR TableExpenses.ImpairmentAC <> 0
	|		OR TableExpenses.ImpairmentOfCF <> 0)
	|";
	#EndRegion
	
	Return QueryText;
	
EndFunction

// 
// Returns:
//  Number -
Function MinimumResidualValueOfRegl() Export

	ParameterValue = 0;
	
							
	Return ParameterValue;

EndFunction

// 
// Returns:
//  Number -
Function MinimumResidualValueOfUpr() Export

	ParameterValue = 0;
	
							
	Return ParameterValue;

EndFunction
 
#EndRegion

#Region RevaluationOfOS_NMA

// Adds text queries to conduct by the revaluation of fixed asset and intangible asset.
//
// Parameters:
//  Query			 - Query - The request that is used during the survey.
//  QueryTexts	 - ValueList - List of requests.
//  KindOfAccountingObjects - String - "OS" or "NMA".
//  Registers - Structure - a list of register names for which you want to table
//
Procedure RequestTextsForRevaluation(Query, QueryTexts, KindOfAccountingObjects, Registers) Export
	
	DocumentName = ?(KindOfAccountingObjects = "FA", "Document.FARevaluation2_4", "Document.IARevaluation2_4");
	
	QueryTextTableRevaluationCost(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers);
	QueryTextTableDepreciationOnRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers);
	QueryTextTableOtherRevaluationGains(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers);
	QueryTextTableOtherRevaluationCosts(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers);
	RequestTextTableOfOtherExpensesAtRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers);
	QueryTextTableOfRegisteredRecordsIncomeExpensesOtherAssetsLiabilitiesAtRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers);
	QueryTextTableRevaluationImpairment(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers);
	
EndProcedure

// Performs the calculation of changes in cost, depreciation and impairment during revaluation in the same way as the document does.
// 
// Parameters:
//  CurCurrentValue - Number - Cost at the time of revaluation
//  CurrentDepreciation - Number - Depreciation at the time of revaluation
//  CurrentImpairment - Number - Impairment at the time of revaluation
//  RevaluationCosts - Number - The cost indicated in the document (restorative or fair)
//  RevaluationMethod - EnumRef.FixedAndIntangibleAssetRevaluationMethods - Revaluation method according to accounting policy
//  RevaluateAtFairValue - Boolean - True if the document indicates a fair cost
// 
// Returns:
//  Structure - Revaluation Result:
// 		* ChangeInValue - Number - 
// 		* ChangeInDepreciation - Number - 
// 		* ChangeOfImpairment - Number - 
Function RevaluationResult(CurCurrentValue, CurrentDepreciation, CurrentImpairment, RevaluationCosts, RevaluationMethod, RevaluateAtFairValue) Export
	
	RevaluationResult = New Structure;
	RevaluationResult.Insert("ChangeInValue", 0);
	RevaluationResult.Insert("ChangeInDepreciation", 0);
	RevaluationResult.Insert("ChangeOfImpairment", 0);
	
	If CurCurrentValue = 0 Then
		Return RevaluationResult;
	EndIf;
	
	If RevaluationMethod = Enums.FixedAndIntangibleAssetRevaluationMethods.CashMethod Then
		
		BookValue = CurCurrentValue - CurrentDepreciation - CurrentImpairment;
		
		// Depreciation is always reset to zero
		RevaluationResult.ChangeInDepreciation = -CurrentDepreciation;
		
		If RevaluationCosts > BookValue
			And (RevaluationCosts - BookValue) <= CurrentImpairment
			And CurrentImpairment > 0 Then
			
			// Additional assessment, the amount of additional assessment is less than the impairment - additional assessment is fully due to impairment
			RevaluationResult.ChangeInValue = 0;
			RevaluationResult.ChangeOfImpairment = -(RevaluationCosts - BookValue);
				
		ElsIf RevaluationCosts > BookValue
			And (RevaluationCosts - BookValue) > CurrentImpairment
			And CurrentImpairment > 0 Then
			
			// Additional valuation, the amount of additional valuation is greater than the impairment - additional valuation partially due to impairment
			RevaluationResult.ChangeInValue = RevaluationCosts - BookValue - CurrentImpairment - CurrentDepreciation;
			RevaluationResult.ChangeOfImpairment = -CurrentImpairment;
				
		Else
					
			RevaluationResult.ChangeInValue = RevaluationCosts - BookValue - CurrentDepreciation;
			RevaluationResult.ChangeOfImpairment = 0;
			
		EndIf;

	ElsIf RevaluationMethod = Enums.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod Then
		
		BookValue = CurCurrentValue - CurrentDepreciation - CurrentImpairment;
		
		If RevaluateAtFairValue Then
			FairValue = RevaluationCosts;
		Else
			FairValue = 
				Round(RevaluationCosts 
					- RevaluationCosts * Round(CurrentDepreciation / CurCurrentValue, 10)
					- RevaluationCosts * Round(CurrentImpairment / CurCurrentValue, 10), 2);
		EndIf;
		
		If BookValue = 0
			Or (CurCurrentValue - CurrentDepreciation) = 0
			Or FairValue = BookValue Then
			
			RevaluationResult.ChangeInValue = 0;
			RevaluationResult.ChangeInDepreciation = 0;
			RevaluationResult.ChangeOfImpairment = 0;
			
		ElsIf FairValue > BookValue Then
			
			If (FairValue - BookValue) <= CurrentImpairment
				And RevaluateAtFairValue Then
				
				// Additional assessment, the amount of additional assessment is less than the impairment - additional assessment is fully due to impairment
				RevaluationResult.ChangeInValue = 0;
				RevaluationResult.ChangeInDepreciation = 0;
				
				RevaluationResult.ChangeOfImpairment = -(FairValue - BookValue);
				
			Else
			
				ZoomRatio = Round(FairValue / BookValue, 10);
				
				RevaluationResult.ChangeInValue = Round(CurCurrentValue * ZoomRatio, 2) - CurCurrentValue;
				RevaluationResult.ChangeInDepreciation = Round(CurrentDepreciation * ZoomRatio, 2) - CurrentDepreciation;
				
				RevaluationResult.ChangeOfImpairment = -CurrentImpairment;
				
			EndIf;
			
		Else
			
			RevaluationOfBookValue = FairValue - BookValue;
			
			If CurrentDepreciation <> 0 Then
				
				ZoomRatio = Round(CurCurrentValue / CurrentDepreciation, 10);
				
				RevaluationResult.ChangeInValue = Round(ZoomRatio * RevaluationOfBookValue / (ZoomRatio - 1), 2);
				RevaluationResult.ChangeInDepreciation = Round(RevaluationOfBookValue / (ZoomRatio - 1), 2);
				
			Else
				
				RevaluationResult.ChangeInValue = RevaluationOfBookValue;
				RevaluationResult.ChangeInDepreciation = 0;
				
			EndIf;
			
			RevaluationResult.ChangeOfImpairment = 0;

		EndIf;
			
	Else
		
		ZoomRatio = Round(RevaluationCosts / CurCurrentValue, 10);
		RevaluationResult.ChangeInValue = RevaluationCosts - CurCurrentValue;
		RevaluationResult.ChangeInDepreciation = Round(CurrentDepreciation * ZoomRatio, 2) - CurrentDepreciation;
		
		RevaluationResult.ChangeOfImpairment = 0;

	EndIf;
	
	Return RevaluationResult;
		
EndFunction

#EndRegion

#Region FADisposal

// Generates the text of the request to reflect the write-off of the cost of the OS in the "Costos" register.
// 
// Parameters:
// 	QueryTexts - ValueList of String -
// 	Query - Query -
// 	
// Returns:
//	String -  
Function TextOfRequestToDeductCostOfFA(QueryTexts, Query = Undefined) Export
	
	NonCurrentAssetsInternal.QueryTextEmptyTableBNACost(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	ImpairmentFAServer.QueryTextEmptyTableDepreciationIn(Query, QueryTexts);

	QueryTextTableTTWriteOffOfCostOfFA(QueryTexts);
	
	ListOfRequests = New Array;
	
	#Region CostWriteOff
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	CostWriteOffTT.FixedAssetsLocation    AS Department,
	|	CostWriteOffTT.FixedAsset   AS FixedAsset,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN CostWriteOffTT.Cost 
	|		ELSE 0 
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostWriteOffTT.LocalCost 
	|		ELSE 0 
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInTA 
	|			THEN CostWriteOffTT.CostInTaxAccounting 
	|		ELSE 0 
	|	END AS CostInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting
	| 				OR DocumentData.RecordInTA
	|					AND CostWriteOffTT.LocalCost = 0
	|
	|			THEN CostWriteOffTT.CostPermanentDifference
	|	
	|		ELSE 0 
	|	END AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostWriteOffTT.LocalCost 
	|		ELSE 0 
	|	END
	|		- CASE 
	|			WHEN DocumentData.RecordInTA 
	|				THEN CostWriteOffTT.CostInTaxAccounting
	|			ELSE 0 
	|		END
	|		- CASE 
	|			WHEN DocumentData.PostInAccounting
	| 					OR DocumentData.RecordInTA
	|						AND CostWriteOffTT.LocalCost = 0
	|
	|				THEN CostWriteOffTT.CostPermanentDifference
	|	
	|			ELSE 0 
	|		END AS CostTemporaryDifference,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostWriteOffTT.CostTargetFinancing 
	|		ELSE 0 
	|	END AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostWriteOffTT.CostTargetFinancingTA 
	|		ELSE 0 
	|	END AS CostTargetFinancingTA,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostWriteOffTT.CostTargetFinancingPD 
	|		ELSE 0 
	|	END AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostWriteOffTT.CostTargetFinancing - CostWriteOffTT.CostTargetFinancingTA - CostWriteOffTT.CostTargetFinancingPD
	|		ELSE 0 
	|	END AS CostTargetFinancingTD,
	|
	|
	|	0                                      AS PreliminaryCostMan,
	|	0                                      AS PreliminaryCostLocal,
	|	0                                      AS CostRevaluationReserve,
	|	0                                      AS CostRevaluationReserveLocal,
	|	0                                      AS CostGainMA,
	|	0                                      AS CostGainLocal,
	|	0                                      AS DisregardedCostTA,
	|	0                                      AS SecurityDepositValue,
	|	
	|	CostWriteOffTT.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	CostWriteOffTT.LineOfBusiness AS LineOfBusiness,
	|	CostWriteOffTT.Leaseholder               AS Leaseholder,
	|	UNDEFINED                           AS CorCounterparty,
	|
	|	&BO_WriteOffFixedAssetsCost                AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	CostWriteOffTT.RowID AS FinRecordID,
	|	&ConfiguringHO_ChargingCostOfFA       AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTWriteOffOfCostOfFA AS CostWriteOffTT
	|		ON CostWriteOffTT.Ref = DocumentData.Ref
	|";
	ListOfRequests.Add(QueryText);  
	#EndRegion
	
	#Region WriteOffOfRevaluationReserve
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	CostWriteOffTT.FixedAssetsLocation    AS Department,
	|	CostWriteOffTT.FixedAsset   AS FixedAsset,
	|
	|	0                                      AS Cost,
	|	0                                      AS LocalCost,
	|	0                                      AS CostInTaxAccounting,
	|	0                                      AS CostPermanentDifference,
	|	0                                      AS CostTemporaryDifference,
	|	0                                      AS CostTargetFinancing,
	|	0                                      AS CostTargetFinancingTA,
	|	0                                      AS CostTargetFinancingPD,
	|	0                                      AS CostTargetFinancingTD,
	|
	|	0                                      AS PreliminaryCostMan,
	|	0                                      AS PreliminaryCostLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN CostWriteOffTT.CostRevaluationReserve 
	|		ELSE 0 
	|	END AS CostRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostWriteOffTT.CostRevaluationReserveLocal 
	|		ELSE 0 
	|	END AS CostRevaluationReserveLocal,
	|
	|	0                                      AS CostGainMA,
	|	0                                      AS CostGainLocal,
	|
	|	0                                      AS DisregardedCostTA,
	|	0                                      AS SecurityDepositValue,
	|	
	|	CostWriteOffTT.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	CostWriteOffTT.LineOfBusiness AS LineOfBusiness,
	|	CostWriteOffTT.Leaseholder               AS Leaseholder,
	|	UNDEFINED                           AS CorCounterparty,
	|
	|	&BO_WriteOffRevaluationReserveOfFixedAssetsCost AS BusinessOperation,
	|	DocumentData.PostInAccounting            AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	&IDOfUnusedFinRecord  AS FinRecordID,
	|	UNDEFINED                           AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTWriteOffOfCostOfFA AS CostWriteOffTT
	|		ON CostWriteOffTT.Ref = DocumentData.Ref  
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting AND CostWriteOffTT.CostRevaluationReserve <> 0
	|		OR DocumentData.PostInAccounting AND CostWriteOffTT.CostRevaluationReserveLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	CostWriteOffTT.FixedAssetsLocation    AS Department,
	|	CostWriteOffTT.FixedAsset   AS FixedAsset,
	|
	|	0                                      AS Cost,
	|	0                                      AS LocalCost,
	|	0                                      AS CostInTaxAccounting,
	|	0                                      AS CostPermanentDifference,
	|	0                                      AS CostTemporaryDifference,
	|	0                                      AS CostTargetFinancing,
	|	0                                      AS CostTargetFinancingTA,
	|	0                                      AS CostTargetFinancingPD,
	|	0                                      AS CostTargetFinancingTD,
	|
	|	0                                      AS PreliminaryCostMan,
	|	0                                      AS PreliminaryCostLocal,
	|
	|	0                                      AS CostRevaluationReserve,
	|	0                                      AS CostRevaluationReserveLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN CostWriteOffTT.CostGainMA 
	|		ELSE 0 
	|	END AS CostGainMA,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostWriteOffTT.CostGainLocal 
	|		ELSE 0 
	|	END AS CostGainLocal,
	|
	|	0                                      AS DisregardedCostTA,
	|	0                                      AS SecurityDepositValue,
	|	
	|	CostWriteOffTT.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	CostWriteOffTT.LineOfBusiness AS LineOfBusiness,
	|	CostWriteOffTT.Leaseholder               AS Leaseholder,
	|	UNDEFINED                           AS CorCounterparty,
	|
	|	&BO_WriteOffRevaluationReserveOfFixedAssetsCost AS BusinessOperation,
	|	DocumentData.PostInAccounting            AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	&IDOfUnusedFinRecord  AS FinRecordID,
	|	UNDEFINED                           AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTWriteOffOfCostOfFA AS CostWriteOffTT
	|		ON CostWriteOffTT.Ref = DocumentData.Ref  
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting AND CostWriteOffTT.CostGainMA <> 0
	|		OR DocumentData.PostInAccounting AND CostWriteOffTT.CostGainLocal <> 0)
	|";
	ListOfRequests.Add(QueryText);  
	#EndRegion
	
	#Region WriteOffOfPreliminaryCost
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	CostWriteOffTT.FixedAssetsLocation    AS Department,
	|	CostWriteOffTT.FixedAsset   AS FixedAsset,
	|
	|	0                                      AS Cost,
	|	0                                      AS LocalCost,
	|	0                                      AS CostInTaxAccounting,
	|	0                                      AS CostPermanentDifference,
	|	0                                      AS CostTemporaryDifference,
	|	0                                      AS CostTargetFinancing,
	|	0                                      AS CostTargetFinancingTA,
	|	0                                      AS CostTargetFinancingPD,
	|	0                                      AS CostTargetFinancingTD,
	|
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN CostWriteOffTT.PreliminaryCostMan 
	|		ELSE 0 
	|	END AS PreliminaryCostMan,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostWriteOffTT.PreliminaryCostLocal 
	|		ELSE 0 
	|	END AS PreliminaryCostLocal,
	|
	|	0                                      AS CostRevaluationReserve,
	|	0                                      AS CostRevaluationReserveLocal,
	|	0                                      AS CostGainMA,
	|	0                                      AS CostGainLocal,
	|	0                                      AS DisregardedCostTA,
	|	0                                      AS SecurityDepositValue,
	|	
	|	CostWriteOffTT.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	CostWriteOffTT.LineOfBusiness AS LineOfBusiness,
	|	CostWriteOffTT.Leaseholder               AS Leaseholder,
	|	UNDEFINED                           AS CorCounterparty,
	|
	|	DocumentData.BusinessOperation  AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting     AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting      AS RecordInManAccounting,
	|	
	|	&IDOfUnusedFinRecord  AS FinRecordID,
	|	UNDEFINED                           AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTWriteOffOfCostOfFA AS CostWriteOffTT
	|		ON CostWriteOffTT.Ref = DocumentData.Ref  
	|
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|
	|	AND (DocumentData.RecordInManAccounting
	|			AND CostWriteOffTT.PreliminaryCostMan <> 0
	|		OR DocumentData.PostInAccounting
	|			AND CostWriteOffTT.PreliminaryCostLocal <> 0)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
	
	Return QueryText;
	
EndFunction

// Generates the text of the request to reflect the depreciation write-off of the OS in the register "Depreciation of the OS".
// 
// Parameters:
// 	QueryTexts - ValueList of String -
// 	
// Returns:
//	String - 
Function RequestTextForDepreciationWriteOffFA(QueryTexts) Export

	QueryTextTableTTDepreciationWriteOffFA(QueryTexts);
	
	QueryText =
	"// Depreciation write-off
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	TTWriteOffOfDepreciation.FixedAssetsLocation        AS Department,
	|	TTWriteOffOfDepreciation.FixedAsset       AS FixedAsset,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTWriteOffOfDepreciation.Depreciation 
	|		ELSE 0 
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTWriteOffOfDepreciation.DepreciationLocal 
	|		ELSE 0 
	|	END AS DepreciationLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInTA 
	|			THEN TTWriteOffOfDepreciation.DepreciationInTaxAccounting 
	|		ELSE 0 
	|	END AS DepreciationInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTWriteOffOfDepreciation.DepreciationPermanentDifferences 
	|		ELSE 0 
	|	END AS DepreciationPermanentDifferences,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTWriteOffOfDepreciation.DepreciationLocal 
	|		ELSE 0 
	|	END
	|		- CASE 
	|			WHEN DocumentData.RecordInTA 
	|				THEN TTWriteOffOfDepreciation.DepreciationInTaxAccounting
	|			ELSE 0 
	|		END
	|		- CASE 
	|			WHEN DocumentData.PostInAccounting 
	|				THEN TTWriteOffOfDepreciation.DepreciationPermanentDifferences
	|			ELSE 0 
	|		END AS DepreciationTD,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTWriteOffOfDepreciation.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTWriteOffOfDepreciation.DepreciationTaxAccountingTargetFinancing 
	|		ELSE 0 
	|	END AS DepreciationTaxAccountingTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTWriteOffOfDepreciation.DepreciationTargetFinancingPD 
	|		ELSE 0 
	|	END AS DepreciationTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTWriteOffOfDepreciation.FixedAssetDepreciationTargetFinancing - TTWriteOffOfDepreciation.DepreciationTaxAccountingTargetFinancing - TTWriteOffOfDepreciation.DepreciationTargetFinancingPD
	|		ELSE 0
	|	END AS DepreciationOfTargetFinancingTD,
	|
	|	0                                            AS DepreciationRevaluationReserve,
	|	0                                            AS DepreciationRevaluationReserveLocal,
	|
	|	TTWriteOffOfDepreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTWriteOffOfDepreciation.LineOfBusiness AS LineOfBusiness,
	|	&BO_FixedAssetDepreciationWriteOff                    AS BusinessOperation,
	|	TTWriteOffOfDepreciation.AccrueDepreciation         AS AccrueDepreciation,
	|
	|	TTWriteOffOfDepreciation.RowID    AS FinRecordID,
	|	&ConfiguringHO_WriteOffFADepreciation           AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDepreciationWriteOffFA AS TTWriteOffOfDepreciation
	|		ON TTWriteOffOfDepreciation.Ref = DocumentData.Ref  
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting AND TTWriteOffOfDepreciation.Depreciation <> 0
	|		OR DocumentData.PostInAccounting AND (TTWriteOffOfDepreciation.DepreciationLocal + TTWriteOffOfDepreciation.FixedAssetDepreciationTargetFinancing) <> 0
	|		OR DocumentData.RecordInTA AND TTWriteOffOfDepreciation.DepreciationInTaxAccounting <> 0)
	|
	|UNION ALL
	|
	|// Write-off of revaluation reserve
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	TTWriteOffOfDepreciation.FixedAssetsLocation        AS Department,
	|	TTWriteOffOfDepreciation.FixedAsset       AS FixedAsset,
	|
	|	0                                            AS Depreciation,
	|	0                                            AS DepreciationLocal,
	|	0                                            AS DepreciationInTaxAccounting,
	|	0                                            AS DepreciationPermanentDifferences,
	|	0                                            AS DepreciationTD,
	|	0                                            AS FixedAssetDepreciationTargetFinancing,
	|	0                                            AS DepreciationTaxAccountingTargetFinancing,
	|	0                                            AS DepreciationTargetFinancingPD,
	|	0                                            AS DepreciationOfTargetFinancingTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTWriteOffOfDepreciation.DepreciationRevaluationReserve 
	|		ELSE 0 
	|	END AS DepreciationRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTWriteOffOfDepreciation.DepreciationRevaluationReserveLocal 
	|		ELSE 0 
	|	END AS DepreciationRevaluationReserveLocal,
	|
	|	TTWriteOffOfDepreciation.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTWriteOffOfDepreciation.LineOfBusiness AS LineOfBusiness,
	|	&BO_WriteOffRevaluationReserveOfFixedAssetDepreciation   AS BusinessOperation,
	|	TTWriteOffOfDepreciation.AccrueDepreciation         AS AccrueDepreciation,
	|
	|	&IDOfUnusedFinRecord        AS FinRecordID,
	|	UNDEFINED                                 AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDepreciationWriteOffFA AS TTWriteOffOfDepreciation
	|		ON TTWriteOffOfDepreciation.Ref = DocumentData.Ref
	|  
	|WHERE
	|	(DocumentData.RecordInManAccounting AND TTWriteOffOfDepreciation.DepreciationRevaluationReserve <> 0
	|		OR DocumentData.PostInAccounting AND TTWriteOffOfDepreciation.DepreciationRevaluationReserveLocal <> 0)
	|";
	
	Return QueryText;
	
EndFunction

/// Generates the text of the request to reflect the write-off of the impairment of the OS in the "Impairment" register.
// 
// Parameters:
// 	QueryTexts - ValueList of String -
// 	
// Returns:
//	String - 
Function TextOfRequestToWriteOffImpairmentOfFA(QueryTexts) Export

	QueryTextTableTTWriteOffOfFAImpairment(QueryTexts);
	
	QueryText =
	"// Write-off of impairment
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	TTImpairmentWriteOff.FixedAssetsLocation        AS Department,
	|	TTImpairmentWriteOff.FixedAsset       AS NonCurrentAsset,
	|	TTImpairmentWriteOff.CGU                   AS CGU,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTImpairmentWriteOff.ImpairmenMan 
	|		ELSE 0 
	|	END AS ImpairmenMan,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTImpairmentWriteOff.ImpairmentLocalAssets 
	|		ELSE 0 
	|	END AS ImpairmentLocalAssets,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTImpairmentWriteOff.LossFromImpairmentMgmt 
	|		ELSE 0 
	|	END AS LossFromImpairmentMgmt,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTImpairmentWriteOff.LossFromImpairmentLocal 
	|		ELSE 0 
	|	END AS LossFromImpairmentLocal,
	|
	|	TTImpairmentWriteOff.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	TTImpairmentWriteOff.LineOfBusiness AS LineOfBusiness,
	|	&BO_WriteOffOfFAImpairment                    AS BusinessOperation,
	|	
	|	TTImpairmentWriteOff.RowID    AS FinRecordID,
	|	&SettingUpHO_WriteOffOfFAImpairment           AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTWriteOffOfFAImpairment AS TTImpairmentWriteOff
	|		ON TTImpairmentWriteOff.Ref = DocumentData.Ref  
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting AND TTImpairmentWriteOff.ImpairmenMan <> 0
	|		OR DocumentData.PostInAccounting AND TTImpairmentWriteOff.ImpairmentLocalAssets <> 0)
	|";
	
	Return QueryText;
	
EndFunction

// Generates the text of the request to reflect the disposal of the OS in the register "Movement of income, expenditure, and other assets".
// 
// Parameters:
// 	QueryTexts - ValueList of String -
// 
// Returns:
//  String - query text.
Function RequestTextDisposalsFARegisteredRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts) Export

	QueryTextTableTTWriteOffOfCostOfFA(QueryTexts);
	QueryTextTableTTDepreciationWriteOffFA(QueryTexts);

	QueryText =
	// Write-off of the cost of Dt 01.09 - Ct 01.01
	"SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	&BO_WriteOffFixedAssetsCost           AS BusinessOperation,
	|	DocumentData.Organization       AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	FATable.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_AccountingObject             AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	FATable.FixedAsset        AS AssetsLiabilitiesDimension,
	|	FATable.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|
	|	DocumentData.Department     AS DebitBusinessUnit,
	|	FATable.LineOfBusiness AS CorLineOfBusiness,
	|	DocumentData.RetirementItem AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	FATable.FixedAsset        AS CorExpenditureDimension,
	|	UNDEFINED                      AS CorDimensionOfAssetsLiabilities,
	|	UNDEFINED                      AS CorFinancialAccountingGroup,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.Cost
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.Cost
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN FATable.LocalCost + FATable.CostTargetFinancing
	|		ELSE 0
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTWriteOffOfCostOfFA AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting AND FATable.Cost <> 0
	|		OR DocumentData.PostInAccounting AND (FATable.LocalCost + FATable.CostTargetFinancing) <> 0)
	|
	|UNION ALL
	|
	// Depreciation write-off Dt 02.01 - Ct 01.09
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	&BO_FixedAssetDepreciationWriteOff         AS BusinessOperation,
	|	DocumentData.Organization       AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	FATable.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.RetirementItem AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	FATable.FixedAsset        AS DimensionOfExpenses,
	|	UNDEFINED                      AS AssetsLiabilitiesDimension,
	|	UNDEFINED                      AS FinancialAccountingGroup,
	|
	|	DocumentData.Department     AS DebitBusinessUnit,
	|	FATable.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_AccountingObject             AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	FATable.FixedAsset        AS CorDimensionOfAssetsLiabilities,
	|	FATable.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.Depreciation
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.Depreciation
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN FATable.DepreciationLocal + FATable.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDepreciationWriteOffFA AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting AND FATable.Depreciation <> 0
	|		OR DocumentData.PostInAccounting AND (FATable.DepreciationLocal + FATable.FixedAssetDepreciationTargetFinancing) <> 0)
	|
	|UNION ALL
	|
	|// Write off revaluation reserve of FA depreciation 
	|SELECT
	|	DocumentData.Ref                        AS Recorder,
	|	DocumentData.Period                        AS Period,
	|	&BO_WriteOffRevaluationReserveOfFixedAssetDepreciation    AS BusinessOperation,
	|	DocumentData.Organization                   AS Organization,
	|
	|	DocumentData.Department                 AS Department,
	|	FATable.LineOfBusiness             AS LineOfBusiness,
	|	&ArticleAP_AccountingObject                         AS AssetRef,
	|	UNDEFINED                                  AS DimensionOfRevenue,
	|	UNDEFINED                                  AS DimensionOfExpenses,
	|	FATable.FixedAsset                    AS AssetsLiabilitiesDimension,
	|	FATable.FinancialAccountingGroup              AS FinancialAccountingGroup,
	|
	|	DocumentData.Department                 AS DebitBusinessUnit,
	|	FATable.LineOfBusiness             AS CorLineOfBusiness,
	|	&Article6_ProfitLoss                       AS CorItem,
	|	UNDEFINED                                  AS CorIncomeDimension,
	|	UNDEFINED                                  AS CorExpenditureDimension,
	|	UNDEFINED                                  AS CorDimensionOfAssetsLiabilities,
	|	FATable.FinancialAccountingGroup              AS CorFinancialAccountingGroup,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDepreciationWriteOffFA AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting AND FATable.DepreciationRevaluationReserve <> 0
	|		OR DocumentData.PostInAccounting AND FATable.DepreciationRevaluationReserveLocal <> 0)
	|
	|UNION ALL
	|
	|// Write off revaluation reserve of FA cost
	|SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_WriteOffRevaluationReserveOfFixedAssetsCost   AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	DocumentData.Department              AS Department,
	|	FATable.LineOfBusiness          AS LineOfBusiness,
	|	&Article6_ProfitLoss                    AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	UNDEFINED                               AS AssetsLiabilitiesDimension,
	|	FATable.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	FATable.LineOfBusiness          AS CorLineOfBusiness,
	|	&ArticleAP_AccountingObject                      AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	FATable.FixedAsset                 AS CorDimensionOfAssetsLiabilities,
	|	FATable.FinancialAccountingGroup           AS CorFinancialAccountingGroup,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.CostRevaluationReserve
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.CostRevaluationReserve
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostRevaluationReserveLocal
	|		ELSE 0
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTWriteOffOfCostOfFA AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting AND FATable.CostRevaluationReserve <> 0
	|		OR DocumentData.PostInAccounting AND FATable.CostRevaluationReserveLocal <> 0)
	|";
	
	Return QueryText;
	
EndFunction

// Generates the text of the request to reflect the disposal of the OS in the register "Movementprochimaktivampassivam".
// 
// Parameters:
// 	QueryTexts - ValueList of String -
// 
// Returns:
//  String - query text.
Function TextOfRequestForDisposalFARegisteredRecordsOnOtherAssetsLiabilities(QueryTexts) Export
	
	QueryTextTableTTWriteOffOfCostOfFA(QueryTexts);
	QueryTextTableTTDepreciationWriteOffFA(QueryTexts);

	QueryText =
	// The revaluation reserve depreciation
	"SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.Organization       AS Organization,
	|	DocumentData.Department     AS Department,
	|	FATable.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_AccountingObject             AS AssetRef,
	|	FATable.FixedAsset        AS Dimension,
	|
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN FATable.DepreciationRevaluationReserveLocal
	|		ELSE 0 
	|	END AS SumCompl,
	|
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.DepreciationRevaluationReserve
	|		ELSE 0 
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.DepreciationRevaluationReserve
	|		ELSE 0 
	|	END AS AmountIncludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.DepreciationRevaluationReserve
	|		ELSE 0 
	|	END AS AmountExcludingVAT,
	|
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	&SettingUpHO_WriteOffOfFADepreciationRevaluationReserve AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDepreciationWriteOffFA AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND FATable.DepreciationRevaluationReserve <> 0 
	|		OR DocumentData.PostInAccounting
	|			AND FATable.DepreciationRevaluationReserveLocal <> 0)
	|
	|UNION ALL
	|
	// Revaluation reserve
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.Organization       AS Organization,
	|	DocumentData.Department     AS Department,
	|	FATable.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_AccountingObject             AS AssetRef,
	|	FATable.FixedAsset        AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN FATable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS SumCompl,
	|
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.CostRevaluationReserve
	|		ELSE 0 
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.CostRevaluationReserve
	|		ELSE 0 
	|	END AS AmountIncludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.CostRevaluationReserve
	|		ELSE 0 
	|	END AS AmountExcludingVAT,
	|
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	&ConfiguringHO_WriteOffOfFARevaluationReserve AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTWriteOffOfCostOfFA AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|			AND FATable.CostRevaluationReserve <> 0
	|		OR DocumentData.PostInAccounting
	|			AND FATable.CostRevaluationReserveLocal <> 0
	|";

	Return QueryText;
	
EndFunction

// Generates the text of the request to reflect the disposal of the OS in the "Other Expenses" register.
// 
// Parameters:
// 	QueryTexts - ValueList of String -
// 
// Returns:
//  String - query text.
Function QueryTextTableTTInitialOtherExpensesAtDisposalOfFA(QueryTexts) Export
	
	QueryTextTableTTWriteOffOfCostOfFA(QueryTexts);
	QueryTextTableTTDepreciationWriteOffFA(QueryTexts);
	
	ListOfMergeRequests = New Array;

	#Region WriteOffFixedAssetsCost // Dt 01.09 - Ct 01.01
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|	CostWriteOffTT.FixedAssetsLocation             AS Department,
	|	DocumentData.RetirementItem           AS ExpenseItem,
	|
	|	CASE
	|		WHEN OwnerRow.FAOwner = VALUE(Catalog.Assets.EmptyRef)
	|			THEN CostWriteOffTT.FixedAsset
	|		ELSE OwnerRow.FAOwner
	|	END                                           AS DimensionOfExpenses,
	|
	|	CostWriteOffTT.LineOfBusiness     AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN CostWriteOffTT.Cost
	|		ELSE 0
	|	END AS AmountIncludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN CostWriteOffTT.Cost
	|		ELSE 0
	|	END AS AmountExcludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN CostWriteOffTT.Cost
	|		ELSE 0
	|	END AS AmountExcludingVATMan,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostWriteOffTT.LocalCost + CostWriteOffTT.CostTargetFinancing
	|		ELSE 0
	|	END AS AmountIncludingVATCompl,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostWriteOffTT.LocalCost + CostWriteOffTT.CostTargetFinancing
	|		ELSE 0
	|	END AS AmountExcludingVATCompl,
	|
	|	CASE 
	|		WHEN NOT &ComplianceCAAccountingIsKept 
	|			THEN 0
	|		WHEN DocumentData.PostInAccounting
	|				OR DocumentData.RecordInTA 
	|					AND CostWriteOffTT.LocalCost = 0
	|					AND CostWriteOffTT.CostTargetFinancing = 0
	| 
	|			THEN CostWriteOffTT.CostPermanentDifference + CostWriteOffTT.CostTargetFinancingPD
	|
	|		ELSE 0
	|	END AS PermanentDifference,
	|
	|	CASE 
	|		WHEN NOT &ComplianceCAAccountingIsKept 
	|			THEN 0
	|		WHEN DocumentData.PostInAccounting 
	|			THEN CostWriteOffTT.LocalCost + CostWriteOffTT.CostTargetFinancing
	|		ELSE 0
	|	END
	|		- CASE 
	|			WHEN DocumentData.RecordInTA
	| 
	|				THEN CostWriteOffTT.CostInTaxAccounting
	|
	|			ELSE 0
	|		END
	|		- CASE 
	|			WHEN DocumentData.PostInAccounting
	| 
	|				THEN CostWriteOffTT.CostPermanentDifference + CostWriteOffTT.CostTargetFinancingPD
	|
	|			ELSE 0
	|		END
	|		- CASE 
	|			WHEN DocumentData.RecordInTA 
	|						AND CostWriteOffTT.LocalCost = 0
	|						AND CostWriteOffTT.CostTargetFinancing = 0
	| 
	|				THEN CostWriteOffTT.CostPermanentDifference
	|
	|			ELSE 0
	|		END AS CostTD,
	|
	|	&BO_WriteOffFixedAssetsCost                         AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|	
	|	CostWriteOffTT.RowID         AS FinRecordID,
	|	&ConfiguringHO_ChargingCostOfFA                AS BusinessTransactionSetting
	|
	|	,DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTWriteOffOfCostOfFA AS CostWriteOffTT
	|		ON CostWriteOffTT.Ref = DocumentData.Ref  
	|
	|		LEFT JOIN TTFATable AS OwnerRow
	|		ON CostWriteOffTT.Ref = OwnerRow.Ref
	|			AND CostWriteOffTT.FixedAsset = OwnerRow.FixedAsset
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region FixedAssetDepreciationWriteOff // Dt 02.01 - Ct 01.09
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|	TTWriteOffOfDepreciation.FixedAssetsLocation           AS Department,
	|	DocumentData.RetirementItem           AS ExpenseItem,
	|
	|	CASE
	|		WHEN OwnerRow.FAOwner = VALUE(Catalog.Assets.EmptyRef)
	|			THEN TTWriteOffOfDepreciation.FixedAsset
	|		ELSE OwnerRow.FAOwner
	|	END                                           AS DimensionOfExpenses,
	|
	|	TTWriteOffOfDepreciation.LineOfBusiness   AS LineOfBusiness,
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTWriteOffOfDepreciation.Depreciation
	|		ELSE 0
	|	END AS AmountIncludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTWriteOffOfDepreciation.Depreciation
	|		ELSE 0
	|	END AS AmountExcludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TTWriteOffOfDepreciation.Depreciation
	|		ELSE 0
	|	END AS AmountExcludingVATMan,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTWriteOffOfDepreciation.DepreciationLocal + TTWriteOffOfDepreciation.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END AS AmountIncludingVATCompl,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTWriteOffOfDepreciation.DepreciationLocal + TTWriteOffOfDepreciation.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END AS AmountExcludingVATCompl,
	|
	|	CASE 
	|		WHEN NOT &ComplianceCAAccountingIsKept 
	|			THEN 0
	|		WHEN DocumentData.PostInAccounting
	|				OR DocumentData.RecordInTA 
	|					AND ISNULL(CostWriteOffTT.LocalCost, 0) = 0
	|					AND ISNULL(CostWriteOffTT.CostTargetFinancing, 0) = 0
	|
	|			THEN TTWriteOffOfDepreciation.DepreciationPermanentDifferences + TTWriteOffOfDepreciation.DepreciationTargetFinancingPD
	|
	|		ELSE 0
	|	END AS PermanentDifference,
	|
	|	CASE 
	|		WHEN NOT &ComplianceCAAccountingIsKept 
	|			THEN 0
	|		WHEN DocumentData.PostInAccounting 
	|			THEN TTWriteOffOfDepreciation.DepreciationLocal + TTWriteOffOfDepreciation.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END
	|		- CASE 
	|			WHEN DocumentData.RecordInTA 
	|				THEN TTWriteOffOfDepreciation.DepreciationInTaxAccounting 
	|			ELSE 0
	|		END
	|		- CASE 
	|			WHEN DocumentData.PostInAccounting
	|
	|				THEN TTWriteOffOfDepreciation.DepreciationPermanentDifferences + TTWriteOffOfDepreciation.DepreciationTargetFinancingPD
	|
	|			ELSE 0
	|		END
	|		- CASE 
	|			WHEN DocumentData.RecordInTA 
	|					AND ISNULL(CostWriteOffTT.LocalCost, 0) = 0
	|					AND ISNULL(CostWriteOffTT.CostTargetFinancing, 0) = 0
	|
	|				THEN TTWriteOffOfDepreciation.DepreciationPermanentDifferences
	|
	|			ELSE 0
	|		END AS CostTD,
	|
	|	&BO_FixedAssetDepreciationWriteOff                       AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|	
	|	TTWriteOffOfDepreciation.RowID       AS FinRecordID,
	|	&ConfiguringHO_WriteOffFADepreciation              AS BusinessTransactionSetting
	|
	|	,DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTDepreciationWriteOffFA AS TTWriteOffOfDepreciation
	|		ON TTWriteOffOfDepreciation.Ref = DocumentData.Ref  
	|
	|		LEFT JOIN TTWriteOffOfCostOfFA AS CostWriteOffTT
	|		ON CostWriteOffTT.Ref = TTWriteOffOfDepreciation.Ref  
	|			AND CostWriteOffTT.FixedAsset = TTWriteOffOfDepreciation.FixedAsset
	|
	|		LEFT JOIN TTFATable AS OwnerRow
	|		ON TTWriteOffOfDepreciation.Ref = OwnerRow.Ref
	|			AND TTWriteOffOfDepreciation.FixedAsset = OwnerRow.FixedAsset
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
		
	#Region WriteOffOfFAImpairment // Dt 02.04 - Ct 01.09
	QueryText =
	"SELECT
	|	DocumentData.Period                          AS Period,
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Organization                     AS Organization,
	|	FATable.FixedAssetsLocation                       AS Department,
	|	DocumentData.RetirementItem           AS ExpenseItem,
	|
	|	CASE
	|		WHEN OwnerRow.FAOwner = VALUE(Catalog.Assets.EmptyRef)
	|			THEN FATable.FixedAsset
	|		ELSE OwnerRow.FAOwner
	|	END AS DimensionOfExpenses,
	|
	|	FATable.LineOfBusiness               AS LineOfBusiness,
	|
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.ImpairmenMan
	|		ELSE 0
	|	END AS AmountIncludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.ImpairmenMan
	|		ELSE 0
	|	END AS AmountExcludingVAT,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.ImpairmenMan
	|		ELSE 0
	|	END AS AmountExcludingVATMan,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN FATable.ImpairmentLocalAssets
	|		ELSE 0
	|	END AS AmountIncludingVATCompl,
	|
	|	CASE 
	|		WHEN DocumentData.PostInAccounting 
	|			THEN FATable.ImpairmentLocalAssets
	|		ELSE 0
	|	END AS AmountExcludingVATCompl,
	|
	|	0 AS PermanentDifference,
	|
	|	CASE 
	|		WHEN NOT &ComplianceCAAccountingIsKept 
	|			THEN 0
	|		WHEN DocumentData.PostInAccounting 
	|			THEN FATable.ImpairmentLocalAssets
	|		ELSE 0
	|	END AS CostTD,
	|
	|	&BO_WriteOffOfFAImpairment          AS BusinessOperation,
	|	UNDEFINED                       AS ItemsLocationAttributes,
	|	
	|	FATable.RowID      AS FinRecordID,
	|	&SettingUpHO_WriteOffOfFAImpairment AS BusinessTransactionSetting
	|
	|	,DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTWriteOffOfFAImpairment AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|		LEFT JOIN TTFATable AS OwnerRow
	|		ON FATable.FixedAsset = OwnerRow.FixedAsset
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
		
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	Return QueryText;
	
EndFunction

// Generates the query text in the table.
// 
// Parameters:
// 	QueryTexts - ValueList of String -
Procedure QueryTextTableTTResidualValueOfFA(QueryTexts) Export

	TableName = "TTResidualValueOfFA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTWriteOffOfCostOfFA(QueryTexts);
	QueryTextTableTTDepreciationWriteOffFA(QueryTexts);
	
	QueryText =
	"// Residual value at full write-off
	|SELECT
	|	DocumentData.Ref                                    AS Ref,
	|	FATable.FixedAsset                                AS FixedAsset,
	|
	|	ISNULL(FACost.Cost, 0) - ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)         AS Cost,
	|	ISNULL(FACost.LocalCost, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) AS LocalCost,
	|	ISNULL(FACost.CostInTaxAccounting, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0)     AS CostInTaxAccounting,
	|	ISNULL(FACost.CostPermanentDifference, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0)     AS CostPermanentDifference,
	|	ISNULL(FACost.CostTemporaryDifference, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationTD, 0)     AS CostTemporaryDifference,
	|	ISNULL(FACost.CostTargetFinancing, 0) - ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0)     AS CostTargetFinancing,
	|	ISNULL(FACost.CostTargetFinancingTA, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing, 0) AS CostTargetFinancingTA,
	|	ISNULL(FACost.CostTargetFinancingPD, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD, 0) AS CostTargetFinancingPD,
	|	ISNULL(FACost.CostTargetFinancingTD, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD, 0) AS CostTargetFinancingTD,
	|
	|	
	|	FATable.FixedAssetsLocation                                 AS FixedAssetsLocation,
	|	FATable.FinancialAccountingGroup                          AS FinancialAccountingGroup,
	|	FATable.LineOfBusiness                         AS LineOfBusiness,
	|	FATable.IncomeItem                                   AS IncomeItem,
	|	FATable.DimensionOfRevenue                                AS DimensionOfRevenue,
	|	DocumentData.RetirementItem                     AS RetirementItem,
	|	
	|	FATable.RowID                             AS RowID
	|
	|INTO TTResidualValueOfFA
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FATable.FixedAsset = FACost.AccountingObject
	|		AND FACost.Ref = FATable.Ref
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FATable.FixedAsset = FixedAssetsDepreciationCharge.AccountingObject
	|			AND FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|	AND (ISNULL(FACost.Cost, 0) - ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0) <> 0
	|		OR ISNULL(FACost.LocalCost, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) <> 0
	|		OR ISNULL(FACost.CostInTaxAccounting, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0) <> 0
	|		OR ISNULL(FACost.CostPermanentDifference, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0) <> 0
	|		OR ISNULL(FACost.CostTemporaryDifference, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationTD, 0) <> 0
	|		OR ISNULL(FACost.CostTargetFinancing, 0) - ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0) <> 0
	|		OR ISNULL(FACost.CostTargetFinancingTA, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing, 0) <> 0
	|		OR ISNULL(FACost.CostTargetFinancingPD, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD, 0) <> 0
	|		OR ISNULL(FACost.CostTargetFinancingTD, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD, 0) <> 0)
	|
	|UNION ALL
	|
	|// Residual value in case of partial write-off
	|SELECT
	|	DocumentData.Ref                                  AS Ref,
	|	FATable.FixedAsset                              AS FixedAsset,
	|
	|	FATable.Cost - ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0)         AS Cost,
	|	FATable.LocalCost - ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) AS LocalCost,
	|	FATable.CostInTaxAccounting - ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0)     AS CostInTaxAccounting,
	|	FATable.CostPermanentDifference - ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0)     AS CostPermanentDifference,
	|	FATable.CostTemporaryDifference - ISNULL(FixedAssetsDepreciationCharge.DepreciationTD, 0)     AS CostTemporaryDifference,
	|	FATable.CostTargetFinancing - ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0)     AS CostTargetFinancing,
	|	FATable.CostTargetFinancingTA - ISNULL(FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing, 0) AS CostTargetFinancingTA,
	|	FATable.CostTargetFinancingPD - ISNULL(FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD, 0) AS CostTargetFinancingPD,
	|	FATable.CostTargetFinancingTD - ISNULL(FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD, 0) AS CostTargetFinancingTD,
	|
	|	
	|	FATable.FixedAssetsLocation                               AS FixedAssetsLocation,
	|	FATable.FinancialAccountingGroup                        AS FinancialAccountingGroup,
	|	FATable.LineOfBusiness                       AS LineOfBusiness,
	|	FATable.IncomeItem                                 AS IncomeItem,
	|	FATable.DimensionOfRevenue                              AS DimensionOfRevenue,
	|	DocumentData.RetirementItem                   AS RetirementItem,
	|
	|	FATable.RowID                           AS RowID
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTWriteOffOfCostOfFA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTDepreciationWriteOffFA AS FixedAssetsDepreciationCharge
	|			ON FATable.Ref = FixedAssetsDepreciationCharge.Ref
	|				AND FATable.FixedAsset = FixedAssetsDepreciationCharge.FixedAsset
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|	AND (FATable.Cost - ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0) <> 0
	|		OR FATable.LocalCost - ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) <> 0
	|		OR FATable.CostInTaxAccounting - ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0) <> 0
	|		OR FATable.CostPermanentDifference - ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0) <> 0
	|		OR FATable.CostTemporaryDifference - ISNULL(FixedAssetsDepreciationCharge.DepreciationTD, 0) <> 0
	|		OR FATable.CostTargetFinancing - ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0) <> 0
	|		OR FATable.CostTargetFinancingTA - ISNULL(FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing, 0) <> 0
	|		OR FATable.CostTargetFinancingPD - ISNULL(FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD, 0) <> 0
	|		OR FATable.CostTargetFinancingTD - ISNULL(FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD, 0) <> 0)";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

// Generates the query text in the table.
// 
// Parameters:
// 	QueryTexts - ValueList of String -
Procedure QueryTextTableTTWriteOffOfCostOfFA(QueryTexts) Export
	
	TableName = "TTWriteOffOfCostOfFA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	
	QueryText =
	"SELECT
	|	FATable.Ref                      AS Ref,
	|	FATable.FixedAsset            AS FixedAsset,
	|
	|	FACost.Cost                 AS Cost,
	|	FACost.LocalCost             AS LocalCost,
	|	FACost.CostInTaxAccounting               AS CostInTaxAccounting,
	|	FACost.CostPermanentDifference               AS CostPermanentDifference,
	|	FACost.CostTemporaryDifference               AS CostTemporaryDifference,
	|	FACost.CostTargetFinancing               AS CostTargetFinancing,
	|	FACost.CostTargetFinancingTA             AS CostTargetFinancingTA,
	|	FACost.CostTargetFinancingPD             AS CostTargetFinancingPD,
	|	FACost.CostTargetFinancingTD             AS CostTargetFinancingTD,
	|
	
	|	FACost.CostRevaluationReserve     AS CostRevaluationReserve,
	|	FACost.CostRevaluationReserveLocal AS CostRevaluationReserveLocal,
	|	FACost.CostGainMA              AS CostGainMA,
	|	FACost.CostGainLocal          AS CostGainLocal,
	|	FACost.PreliminaryCostMan      AS PreliminaryCostMan,
	|	FACost.PreliminaryCostLocal  AS PreliminaryCostLocal,
	|	FACost.SecurityDepositValue            AS SecurityDepositValue,
	|
	|	1                                     AS PercentageOfWriteOffs,
	|	1                                     AS ACWriteOffPercentage,
	|	1                                     AS PercentageOfCFWriteOffs,
	|	1                                     AS ShareOfWriteOffTa,
	|	1                                     AS ShareOfNUCFWriteOff,
	|	1                                     AS ShareOfPDWriteOffs,
	|	1                                     AS ShareOfWriteOffOfPRTF,
	|	
	|	FATable.FixedAssetsLocation             AS FixedAssetsLocation,
	|	FATable.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	FATable.LineOfBusiness     AS LineOfBusiness,
	|	FATable.Leaseholder                   AS Leaseholder,
	|	FATable.AccrueDepreciation              AS AccrueDepreciation,
	|	FATable.IncomeItem               AS IncomeItem,
	|	FATable.DimensionOfRevenue            AS DimensionOfRevenue,
	|	
	|	FATable.RowID         AS RowID
	|
	|INTO TTWriteOffOfCostOfFA
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FATable.FixedAsset = FACost.AccountingObject
	|			AND FACost.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|
	|UNION ALL
	|
	// Partial write-off of the cost
	|SELECT
	|	FATable.Ref           AS Ref,
	|	FATable.FixedAsset AS FixedAsset,
	|
	|	FATable.AmountManagementAccounting  AS Cost,
	|	FATable.ChargeAmountAccounting - FATable.ChargeAmountAccounting * ISNULL(FACost.ShareOfCentralBank, 0) AS LocalCost,
	|	FATable.AmountTaxAccounting - FATable.AmountTaxAccounting * ISNULL(FACost.CFNUShare, 0) AS CostInTaxAccounting,
	|	FATable.AmountPermanentDifference - FATable.AmountPermanentDifference * ISNULL(FACost.CfprShare, 0) AS CostPermanentDifference,
	|
	|	CAST((FATable.ChargeAmountAccounting - FATable.ChargeAmountAccounting * ISNULL(FACost.ShareOfCentralBank, 0)) AS NUMBER(31,2))
	|		- CAST((FATable.AmountTaxAccounting - FATable.AmountTaxAccounting * ISNULL(FACost.CFNUShare, 0)) AS NUMBER(31,2))
	|		- CAST((FATable.AmountPermanentDifference - FATable.AmountPermanentDifference * ISNULL(FACost.CfprShare, 0)) AS NUMBER(31,2)) AS CostTemporaryDifference,
	|
	|	FATable.ChargeAmountAccounting * ISNULL(FACost.ShareOfCentralBank, 0) AS CostTargetFinancing,
	|	FATable.AmountTaxAccounting * ISNULL(FACost.CFNUShare, 0) AS CostTargetFinancingTA,
	|	FATable.AmountPermanentDifference * ISNULL(FACost.CfprShare, 0) AS CostTargetFinancingPD,
	|
	|	CAST((FATable.ChargeAmountAccounting * ISNULL(FACost.ShareOfCentralBank, 0)) AS NUMBER(31,2))
	|		- CAST((FATable.AmountTaxAccounting * ISNULL(FACost.CFNUShare, 0)) AS NUMBER(31,2))
	|		- CAST((FATable.AmountPermanentDifference * ISNULL(FACost.CfprShare, 0)) AS NUMBER(31,2)) AS CostTargetFinancingTD,
	|
	|
	|	ISNULL(FACost.CostRevaluationReserve, 0)
	|		* CASE WHEN ISNULL(FACost.Cost, 0) = 0
	|			THEN 1
	|			ELSE CAST(CAST(FATable.AmountManagementAccounting AS NUMBER(31, 10)) 
	|					/ FACost.Cost AS NUMBER(31, 10))
	|		END AS CostRevaluationReserve,
	|
	|	ISNULL(FACost.CostRevaluationReserveLocal, 0)
	|		* CASE WHEN ISNULL(FACost.LocalCost, 0) = 0
	|			THEN 1
	|			ELSE CAST(CAST(FATable.ChargeAmountAccounting - FATable.ChargeAmountAccounting * ISNULL(FACost.ShareOfCentralBank, 0) AS NUMBER(31, 10)) 
	|					/ FACost.LocalCost AS NUMBER(31, 10))
	|		END AS CostRevaluationReserveLocal,
	|
	|	ISNULL(FACost.CostGainMA, 0)
	|		* CASE WHEN ISNULL(FACost.Cost, 0) = 0
	|			THEN 1
	|			ELSE CAST(CAST(FATable.AmountManagementAccounting AS NUMBER(31, 10)) 
	|					/ FACost.Cost AS NUMBER(31, 10))
	|		END AS CostGainMA,
	|
	|	ISNULL(FACost.CostGainLocal, 0)
	|		* CASE WHEN ISNULL(FACost.LocalCost, 0) = 0
	|			THEN 1
	|			ELSE CAST(CAST(FATable.ChargeAmountAccounting - FATable.ChargeAmountAccounting * ISNULL(FACost.ShareOfCentralBank, 0) AS NUMBER(31, 10)) 
	|					/ FACost.LocalCost AS NUMBER(31, 10))
	|		END AS CostGainLocal,
	|
	|	0 AS PreliminaryCostMan,
	|	0 AS PreliminaryCostLocal,
	|	0 AS SecurityDepositValue,
	|
	|	CASE 
	|		WHEN ISNULL(FACost.Cost, 0) = 0
	|			THEN 1
	|		ELSE CAST(CAST(FATable.AmountManagementAccounting AS NUMBER(31, 10)) 
	|						/ FACost.Cost AS NUMBER(31, 10))
	|	END AS PercentageOfWriteOffs,
	|
	|	CASE 
	|		WHEN ISNULL(FACost.LocalCost, 0) = 0
	|			THEN 1
	|		ELSE CAST(CAST(FATable.ChargeAmountAccounting - FATable.ChargeAmountAccounting * ISNULL(FACost.ShareOfCentralBank, 0) AS NUMBER(31, 10)) 
	|						/ FACost.LocalCost AS NUMBER(31, 10))
	|	END AS ACWriteOffPercentage,
	|
	|	CASE 
	|		WHEN ISNULL(FACost.CostTargetFinancing, 0) = 0
	|			THEN 1
	|		ELSE CAST(CAST(FATable.ChargeAmountAccounting * ISNULL(FACost.ShareOfCentralBank, 0) AS NUMBER(31, 10)) 
	|						/ FACost.CostTargetFinancing AS NUMBER(31, 10))
	|	END AS PercentageOfCFWriteOffs,
	|
	|	CASE 
	|		WHEN ISNULL(FACost.CostInTaxAccounting, 0) = 0
	|			THEN 1
	|		ELSE CAST(CAST(FATable.AmountTaxAccounting - FATable.AmountTaxAccounting * ISNULL(FACost.CFNUShare, 0) AS NUMBER(31, 10)) 
	|						/ FACost.CostInTaxAccounting AS NUMBER(31, 10))
	|	END AS ShareOfWriteOffTa,
	|
	|	CASE 
	|		WHEN ISNULL(FACost.CostTargetFinancingTA, 0) = 0
	|			THEN 1
	|		ELSE CAST(CAST(FATable.AmountTaxAccounting * ISNULL(FACost.CFNUShare, 0) AS NUMBER(31, 10)) 
	|						/ FACost.CostTargetFinancingTA AS NUMBER(31, 10))
	|	END AS ShareOfNUCFWriteOff,
	|
	|	CASE 
	|		WHEN ISNULL(FACost.CostPermanentDifference, 0) = 0
	|			THEN 1
	|		ELSE CAST(CAST(FATable.AmountPermanentDifference - FATable.AmountPermanentDifference * ISNULL(FACost.CfprShare, 0) AS NUMBER(31, 10)) 
	|						/ FACost.CostPermanentDifference AS NUMBER(31, 10))
	|	END AS ShareOfPDWriteOffs,
	|
	|	CASE 
	|		WHEN ISNULL(FACost.CostTargetFinancingPD, 0) = 0
	|			THEN 1
	|		ELSE CAST(CAST(FATable.AmountPermanentDifference * ISNULL(FACost.CfprShare, 0) AS NUMBER(31, 10)) 
	|						/ FACost.CostTargetFinancingPD AS NUMBER(31, 10))
	|	END AS ShareOfWriteOffOfPRTF,
	|
	|	FATable.FixedAssetsLocation             AS FixedAssetsLocation,
	|	FATable.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	FATable.LineOfBusiness     AS LineOfBusiness,
	|	FATable.Leaseholder                   AS Leaseholder,
	|	FATable.AccrueDepreciation              AS AccrueDepreciation,
	|	FATable.IncomeItem               AS IncomeItem,
	|	FATable.DimensionOfRevenue            AS DimensionOfRevenue,
	|	
	|	FATable.RowID         AS RowID
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset 
	|
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|
	|INDEX BY
	|	Ref
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

// Generates the query text in the table.
// 
// Parameters:
// 	QueryTexts - ValueList of String -
Procedure QueryTextTableTTDepreciationWriteOffFA(QueryTexts) Export

	TableName = "TTDepreciationWriteOffFA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTWriteOffOfCostOfFA(QueryTexts);
	
	QueryText =
	"// Full depreciation write-off
	|SELECT
	|	FATable.Ref                          AS Ref,
	|	FATable.FixedAsset                AS FixedAsset,
	|
	|	FATable.FixedAssetsLocation                 AS FixedAssetsLocation,
	|	FATable.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	FATable.LineOfBusiness         AS LineOfBusiness,
	|	FATable.AccrueDepreciation                  AS AccrueDepreciation,
	|	
	|	FATable.RowID             AS RowID,
	|
	|	FixedAssetsDepreciationCharge.Depreciation                 AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal             AS DepreciationLocal,
	|	FixedAssetsDepreciationCharge.DepreciationInTaxAccounting               AS DepreciationInTaxAccounting,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences               AS DepreciationPermanentDifferences,
	|	FixedAssetsDepreciationCharge.DepreciationTD               AS DepreciationTD,
	|	FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing               AS FixedAssetDepreciationTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing             AS DepreciationTaxAccountingTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD             AS DepreciationTargetFinancingPD,
	|	FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD             AS DepreciationOfTargetFinancingTD,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserve     AS DepreciationRevaluationReserve,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocal AS DepreciationRevaluationReserveLocal
	|
	|INTO TTDepreciationWriteOffFA
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|
	|UNION ALL
	|
	|// Partial write-off of depreciation
	|SELECT
	|	DocumentData.Ref                    AS Ref,
	|	FATable.FixedAsset                AS FixedAsset,
	|
	|	FATable.FixedAssetsLocation                 AS FixedAssetsLocation,
	|	FATable.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	FATable.LineOfBusiness         AS LineOfBusiness,
	|	FATable.AccrueDepreciation                  AS AccrueDepreciation,
	|	
	|	FATable.RowID             AS RowID,
	|
	// Depreciation
	|	CASE
	|		WHEN FixedAssetsDepreciationCharge.Depreciation = ISNULL(FACost.Cost, 0)
	|			THEN WriteOffFixedAssetsCost.Cost
	|		ELSE CAST(FixedAssetsDepreciationCharge.Depreciation * WriteOffFixedAssetsCost.PercentageOfWriteOffs AS NUMBER(31,2))     
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE
	|		WHEN FixedAssetsDepreciationCharge.DepreciationLocal = ISNULL(FACost.LocalCost, 0)
	|			THEN WriteOffFixedAssetsCost.LocalCost
	|		ELSE CAST(FixedAssetsDepreciationCharge.DepreciationLocal * WriteOffFixedAssetsCost.ACWriteOffPercentage AS NUMBER(31,2))
	|	END AS DepreciationLocal,
	|
	// DepreciationInTaxAccounting
	|	CASE
	|		WHEN FixedAssetsDepreciationCharge.DepreciationInTaxAccounting = ISNULL(FACost.CostInTaxAccounting, 0)
	|			THEN WriteOffFixedAssetsCost.CostInTaxAccounting
	|		ELSE CAST(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting * WriteOffFixedAssetsCost.ShareOfWriteOffTa AS NUMBER(31,2))
	|	END AS DepreciationInTaxAccounting,
	|
	// DepreciationPermanentDifferences
	|	CASE
	|		WHEN FixedAssetsDepreciationCharge.DepreciationPermanentDifferences = ISNULL(FACost.CostPermanentDifference, 0)
	|			THEN WriteOffFixedAssetsCost.CostPermanentDifference
	|		ELSE CAST(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences * WriteOffFixedAssetsCost.ShareOfPDWriteOffs AS NUMBER(31,2))
	|	END AS DepreciationPermanentDifferences,
	|
	// DepreciationTD
	|	CASE
	|		WHEN FixedAssetsDepreciationCharge.DepreciationLocal = ISNULL(FACost.LocalCost, 0)
	|			THEN WriteOffFixedAssetsCost.LocalCost
	|		ELSE CAST(FixedAssetsDepreciationCharge.DepreciationLocal * WriteOffFixedAssetsCost.ACWriteOffPercentage AS NUMBER(31,2))
	|	END
	|		- CASE
	|				WHEN FixedAssetsDepreciationCharge.DepreciationInTaxAccounting = ISNULL(FACost.CostInTaxAccounting, 0)
	|					THEN WriteOffFixedAssetsCost.CostInTaxAccounting
	|				ELSE CAST(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting * WriteOffFixedAssetsCost.ShareOfWriteOffTa AS NUMBER(31,2))
	|			END
	|		- CASE
	|				WHEN FixedAssetsDepreciationCharge.DepreciationPermanentDifferences = ISNULL(FACost.CostPermanentDifference, 0)
	|					THEN WriteOffFixedAssetsCost.CostPermanentDifference
	|				ELSE CAST(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences * WriteOffFixedAssetsCost.ShareOfPDWriteOffs AS NUMBER(31,2))
	|			END AS DepreciationTD,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE
	|		WHEN FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing = ISNULL(FACost.CostTargetFinancing, 0)
	|			THEN WriteOffFixedAssetsCost.CostTargetFinancing
	|		ELSE CAST(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing  * WriteOffFixedAssetsCost.PercentageOfCFWriteOffs  AS NUMBER(31,2))
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	// DepreciationTaxAccountingTargetFinancing
	|	CASE
	|		WHEN FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing = ISNULL(FACost.CostTargetFinancing, 0)
	|			THEN WriteOffFixedAssetsCost.CostTargetFinancing
	|		ELSE CAST(FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing * WriteOffFixedAssetsCost.ShareOfNUCFWriteOff  AS NUMBER(31,2))
	|	END AS DepreciationTaxAccountingTargetFinancing,
	|
	// DepreciationTargetFinancingPD
	|	CASE
	|		WHEN FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD = ISNULL(FACost.CostTargetFinancingPD, 0)
	|			THEN WriteOffFixedAssetsCost.CostTargetFinancingPD
	|		ELSE CAST(FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD * WriteOffFixedAssetsCost.ShareOfWriteOffOfPRTF  AS NUMBER(31,2))
	|	END AS DepreciationTargetFinancingPD,
	|
	// DepreciationOfTargetFinancingTD
	|	CASE
	|		WHEN FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing = ISNULL(FACost.CostTargetFinancing, 0)
	|			THEN WriteOffFixedAssetsCost.CostTargetFinancing
	|		ELSE CAST(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing  * WriteOffFixedAssetsCost.PercentageOfCFWriteOffs  AS NUMBER(31,2))
	|	END
	|		- CASE
	|				WHEN FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing = ISNULL(FACost.CostTargetFinancing, 0)
	|					THEN WriteOffFixedAssetsCost.CostTargetFinancing
	|				ELSE CAST(FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing * WriteOffFixedAssetsCost.ShareOfNUCFWriteOff  AS NUMBER(31,2))
	|			END
	|		- CASE
	|				WHEN FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD = ISNULL(FACost.CostTargetFinancingPD, 0)
	|					THEN WriteOffFixedAssetsCost.CostTargetFinancingPD
	|				ELSE CAST(FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD * WriteOffFixedAssetsCost.ShareOfWriteOffOfPRTF  AS NUMBER(31,2))
	|			END AS DepreciationOfTargetFinancingTD,
	|
	|	CAST(FixedAssetsDepreciationCharge.DepreciationRevaluationReserve * WriteOffFixedAssetsCost.PercentageOfWriteOffs AS NUMBER(31,2)) AS DepreciationRevaluationReserve,
	|	CAST(FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocal * WriteOffFixedAssetsCost.ACWriteOffPercentage AS NUMBER(31,2)) AS DepreciationRevaluationReserveLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref  
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTWriteOffOfCostOfFA AS WriteOffFixedAssetsCost
	|		ON WriteOffFixedAssetsCost.Ref = FATable.Ref
	|			AND WriteOffFixedAssetsCost.FixedAsset = FATable.FixedAsset 
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|
	|INDEX BY
	|	Ref
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

// Generates the query text in the table.
// 
// Parameters:
// 	QueryTexts - ValueList of String -
Procedure QueryTextTableTTWriteOffOfFAImpairment(QueryTexts) Export

	TableName = "TTWriteOffOfFAImpairment";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"// Full write-off of FA impairment.
	|SELECT
	|	DocumentData.Ref                    AS Ref,
	|	ISNULL(OwnerRow.FixedAsset, FATable.FixedAsset) AS FixedAsset,
	|
	|	FATable.FixedAssetsLocation                 AS FixedAssetsLocation,
	|	FATable.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	FATable.LineOfBusiness         AS LineOfBusiness,
	|	
	|	FATable.RowID             AS RowID,
	|	
	|	FAImpairment.CGU                        AS CGU,
	|
	|	FAImpairment.ImpairmenMan              AS ImpairmenMan,
	|	FAImpairment.ImpairmentLocalAssets             AS ImpairmentLocalAssets,
	|
	|	FAImpairment.LossFromImpairmentMgmt              AS LossFromImpairmentMgmt,
	|	FAImpairment.LossFromImpairmentLocal             AS LossFromImpairmentLocal
	|
	|INTO TTWriteOffOfFAImpairment
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref 
	|
	|		LEFT JOIN TTFATable AS OwnerRow
	|		ON OwnerRow.Ref = FATable.Ref
	|			AND OwnerRow.RowID = FATable.RowID
	|			AND OwnerRow.FixedAsset.OSType IN (
	|				VALUE(Enum.FATypes.Asset),
	|				VALUE(Enum.FATypes.GroupFA),
	|				VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets)) 
	|
	|		INNER JOIN TT_ImpairmentFA AS FAImpairment
	|		ON FAImpairment.Ref = FATable.Ref
	|			AND FAImpairment.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|
	|UNION ALL
	|
	|// Partial write-off of FA impairment.
	|SELECT
	|	DocumentData.Ref                    AS Ref,
	|	ISNULL(OwnerRow.FixedAsset, FATable.FixedAsset) AS FixedAsset,
	|
	|	FATable.FixedAssetsLocation                 AS FixedAssetsLocation,
	|	FATable.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	FATable.LineOfBusiness         AS LineOfBusiness,
	|	
	|	FATable.RowID             AS RowID,
	|	
	|	FAImpairment.CGU                        AS CGU,
	|
	|	FAImpairment.ImpairmenMan 
	|		* TTWriteOffOfCostOfFA.PercentageOfWriteOffs    AS ImpairmenMan,
	|
	|	FAImpairment.ImpairmentLocalAssets 
	|		* TTWriteOffOfCostOfFA.ACWriteOffPercentage  AS ImpairmentLocalAssets,
	|
	|	FAImpairment.LossFromImpairmentMgmt 
	|		* TTWriteOffOfCostOfFA.PercentageOfWriteOffs    AS LossFromImpairmentMgmt,
	|
	|	FAImpairment.LossFromImpairmentLocal 
	|		* TTWriteOffOfCostOfFA.ACWriteOffPercentage  AS LossFromImpairmentLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFATable AS OwnerRow
	|		ON OwnerRow.RowID = FATable.RowID
	|			AND OwnerRow.FixedAsset.OSType IN (
	|				VALUE(Enum.FATypes.Asset),
	|				VALUE(Enum.FATypes.GroupFA),
	|				VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets)) 
	|
	|		INNER JOIN TT_ImpairmentFA AS FAImpairment
	|		ON FAImpairment.AccountingObject = FATable.FixedAsset
	|			AND FAImpairment.Ref = FATable.Ref
	|		
	|			LEFT JOIN TTWriteOffOfCostOfFA AS TTWriteOffOfCostOfFA
	|			ON FAImpairment.AccountingObject  = TTWriteOffOfCostOfFA.FixedAsset
	|				AND TTWriteOffOfCostOfFA.Ref = FAImpairment.Ref
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

#EndRegion

#Region Reports

// The report brings together sub-cell.
// It is used in reports that vertically display indicators of BU, NU, PU, VP, and UU.
//
// Parameters:
//  TabDoc					 - SpreadsheetDocument - Table document of the report.
//  ListOfCellGroups		 - Array			 - List of cell groups.
//  ListOfSubordinateCells	 - Array			 - A list of cells that will be combined with a group of cells.
//
Procedure MergeSubordinateCells(TabDoc, ListOfCellGroups, ListOfSubordinateCells) Export
	
	HeaderFound = False;
		
	For IndRow = 1 To TabDoc.TableHeight Do
		
		For HeaderStartColumn = 1 To TabDoc.TableWidth Do
			
			TableCellArea = TabDoc.Area(IndRow, HeaderStartColumn);
			HeaderFound = ListOfCellGroups.Find(TableCellArea.Text) <> Undefined;
			If HeaderFound Then
				Break;
			EndIf;
		EndDo;
				
		If HeaderFound Then
			
			For IndKol = HeaderStartColumn To TabDoc.TableWidth Do
				
				Offset = 0;
				
				For Cnt = 0 To 5 Do
					
					TableCellArea = TabDoc.Area(IndRow + Cnt, IndKol);
					
					If ListOfCellGroups.Find(TableCellArea.Text) <> Undefined Then
						Break;
					EndIf;
					
					Offset = Offset + 1;
					
				EndDo;
				
				TableCellArea = TabDoc.Area(
									IndRow + Offset, 
									IndKol, 
									IndRow + Offset, 
									IndKol);
									
				TitleText = TableCellArea.Text;
				
				HeaderHeight = 0;
				For IndexOf = 1 To 10 Do
					
					TableCellArea = TabDoc.Area(
											IndRow+IndexOf+Offset, 
											IndKol, 
											IndRow+IndexOf+Offset, 
											IndKol);
											
					NextCell = TableCellArea.Text;
					
					If ListOfSubordinateCells.Find(NextCell) = Undefined Then
						Break;
					EndIf;
					
					HeaderHeight = HeaderHeight + 1;
					
				EndDo;
				
				MergedArea = TabDoc.Area(IndRow+Offset, IndKol, IndRow + HeaderHeight + Offset, IndKol);
				MergedArea.Merge();
				MergedArea.Text = TitleText;
				MergedArea.TextPlacement = SpreadsheetDocumentTextPlacementType.Wrap;
				
			EndDo; 
				
			Return;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Verifies that the report is generated starting from the start date of accounting version 2.4.
//
// Parameters:
//  BeginOfPeriod	 - Date - Start of the report period.
//  PeriodEnding - Date - End of the report period.
//  MessageTemplate	 - String - The template of the error message.
//  Cancel			 - Boolean - a sign of failure.
// 
// Returns:
//  Boolean - False if the report is generated before the accounting start date of version 2.4.
//
Function CheckVersion24ReportPeriod(BeginOfPeriod, PeriodEnding, MessageTemplate, Cancel) Export

	If Not GetFunctionalOption("UseNonCurrentAssets2_2") Then
		Return True;
	EndIf;
	
	AccountingStartDate = NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24();
	
	If ValueIsFilled(BeginOfPeriod)
			And BeginOfPeriod < AccountingStartDate
		Or ValueIsFilled(PeriodEnding)
			And PeriodEnding < AccountingStartDate Then
			
		Cancel = True;
		
		MessageText = StrTemplate(MessageTemplate, Format(AccountingStartDate, "DLF=D"));
		Common.MessageToUser(MessageText,,,, Cancel); 
		
		Return False;
		
	EndIf;
	
	Return True;	
	
EndFunction
 
#EndRegion

#Region QueriesTexts

// Generates the Query Text of the VT_STOY Value table.
// 
// Parameters:
//  Query - Query -
//  QueryTexts - ValueList of String -
//  TableName - Undefined - 
Procedure QueryTextEmptyTableBNACost(Query, QueryTexts, TableName = Undefined) Export

	If TableName = Undefined Then
		TableName = "TT_CostOfVNA";
	EndIf; 
	
	If Query.TempTablesManager <> Undefined
		And Query.TempTablesManager.Tables.Find(TableName) <> Undefined Then
		Return;
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	NULL AS Ref,
	|	NULL AS Date,
	|	NULL AS Organization,
	|	NULL AS AccountingObject,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostInTaxAccounting,
	|	0 AS CostPermanentDifference,
	|	0 AS CostTemporaryDifference,
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingTA,
	|	0 AS CostTargetFinancingPD,
	|	0 AS CostTargetFinancingTD,
	|	0 AS DepreciationAllowance,
	|	0 AS SecurityDepositValue,
	|	0 AS PreliminaryCostMan,
	|	0 AS PreliminaryCostLocal,
	|	0 AS CostRevaluationReserve,
	|	0 AS CostRevaluationReserveLocal,
	|	0 AS CostGainMA,
	|	0 AS CostGainLocal,
	|	0 AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0 AS ShareOfCentralBank,
	|	0 AS CFNUShare,
	|	0 AS CfprShare,
	|
	|	"""" AS RowID
	|
	|INTO TT_CostOfVNA";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

// Generates the Query Text of the VT_AMORTIZATION table.
// 
// Parameters:
//  Query - Query -
//  QueryTexts - ValueList of String -
//  TableName - String, Undefined - 
Procedure QueryTextEmptyTableDepreciationVNA(Query, QueryTexts, TableName = Undefined) Export

	If TableName = Undefined Then
		TableName = "TT_DepreciationOfVNA";
	EndIf; 
	
	If Query.TempTablesManager <> Undefined
		And Query.TempTablesManager.Tables.Find(TableName) <> Undefined Then
		Return;
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	NULL AS Ref,
	|	NULL AS Date,
	|	NULL AS Organization,
	|	NULL AS AccountingObject,
	|
	|	0 AS Depreciation,
	|	0 AS DepreciationLocal,
	|	0 AS DepreciationInTaxAccounting,
	|	0 AS DepreciationPermanentDifferences,
	|	0 AS DepreciationTD,
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationTaxAccountingTargetFinancing,
	|	0 AS DepreciationTargetFinancingPD,
	|	0 AS DepreciationOfTargetFinancingTD,
	|
	|	0 AS DepreciationRevaluationReserve,
	|	0 AS DepreciationRevaluationReserveLocal,
	|	FALSE AS AccrueDepreciation
	|
	|INTO TT_DepreciationOfVNA";
	
	QueryText = StrReplace(QueryText, "TT_DepreciationOfVNA", TableName);
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

// Generates the Query Text of the table Value grouped.
// 
// Parameters:
//  Query - Query - 
// 	QueryTexts - ValueList of String - 
Procedure QueryTextTTCostBHAGrouped(Query, QueryTexts) Export

	TableName = "TTCostBHAGrouped";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextEmptyTableBNACost(Query, QueryTexts);
		
	QueryText = 
	"SELECT
	|	CostOfVNA.Ref                    AS Ref,
	|	CostOfVNA.AccountingObject               AS AccountingObject,
	|	SUM(CostOfVNA.Cost)          AS Cost,
	|	SUM(CostOfVNA.LocalCost)      AS LocalCost,
	|	SUM(CostOfVNA.CostInTaxAccounting)        AS CostInTaxAccounting,
	|	SUM(CostOfVNA.CostPermanentDifference)        AS CostPermanentDifference,
	|	SUM(CostOfVNA.CostTemporaryDifference)        AS CostTemporaryDifference,
	|	SUM(CostOfVNA.CostTargetFinancing)        AS CostTargetFinancing,
	|	SUM(CostOfVNA.CostTargetFinancingTA)      AS CostTargetFinancingTA,
	|	SUM(CostOfVNA.CostTargetFinancingPD)      AS CostTargetFinancingPD,
	|	SUM(CostOfVNA.CostTargetFinancingTD)      AS CostTargetFinancingTD
	|
	|INTO TTCostBHAGrouped
	|
	|FROM
	|	TT_CostOfVNA AS CostOfVNA
	|
	|GROUP BY
	|	CostOfVNA.Ref,
	|	CostOfVNA.AccountingObject
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

// Generates the Query Text of the table in the Amortization grouped.
// 
// Parameters:
//  Query - Query - 
// 	QueryTexts - ValueList of String - 
Procedure QueryTextTTDepreciationVNAGrouped(Query, QueryTexts) Export

	TableName = "TTDepreciationVNAGrouped";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
		
	QueryText = 
	"SELECT
	|	SUM(DepreciationOfVNA.Depreciation)          AS Depreciation,
	|	SUM(DepreciationOfVNA.DepreciationLocal)      AS DepreciationLocal,
	|	SUM(DepreciationOfVNA.DepreciationInTaxAccounting)        AS DepreciationInTaxAccounting,
	|	SUM(DepreciationOfVNA.DepreciationPermanentDifferences)        AS DepreciationPermanentDifferences,
	|	SUM(DepreciationOfVNA.DepreciationTD)        AS DepreciationTD,
	|	SUM(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing)        AS FixedAssetDepreciationTargetFinancing,
	|	SUM(DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing)      AS DepreciationTaxAccountingTargetFinancing,
	|	SUM(DepreciationOfVNA.DepreciationTargetFinancingPD)      AS DepreciationTargetFinancingPD,
	|	SUM(DepreciationOfVNA.DepreciationOfTargetFinancingTD)      AS DepreciationOfTargetFinancingTD
	|INTO TTDepreciationVNAGrouped
	|FROM
	|	TT_DepreciationOfVNA AS DepreciationOfVNA
	|WHERE
	|	DepreciationOfVNA.Ref = &Ref";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

// Generates the Query Text of the table in the list.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
//	Add_Fields - String -
Procedure QueryTextTableTTFAList(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable", Add_Fields = "") Export
	
	TableName = "TTFAList";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset AS FixedAsset
	|	,&AdditionalFields
	|
	|INTO TTFAList
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|	
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization
	|";
	
	If ValueIsFilled(Add_Fields) Then
		
		TextAdditionalFields = "";
		PartOfRequestAs = " AS "; // @query-part
		FieldList = StrSplit(Add_Fields, ",");
		For Each FieldName In FieldList Do
			TextAdditionalFields = TextAdditionalFields + "
			|	, " + "DocumentData" + "." + FieldName + PartOfRequestAs + FieldName;
		EndDo; 
		
		QueryText = StrReplace(QueryText, ",&AdditionalFields", TextAdditionalFields); 
		
	Else
		QueryText = StrReplace(QueryText, ",&AdditionalFields", "");
	EndIf; 

	QueryText = StrReplace(QueryText, "DocumentDataFATable", NameOfAccountingObjectTable);
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

// Generates the Query Text of the vtparameters accounting table.
// 
// Parameters:
//  QueryTexts - ValueList of String - Request texts.
//  NameOfAccountingObjectTable - String - the full name of the document.
//  TempTableName - String, Undefined - name of the temporary table.
Procedure QueryTextTableTTFAAccountingParameters(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable", TempTableName = Undefined) Export

	TableName = ?(TempTableName <> Undefined, TempTableName, "TTFAAccountingParameters");
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTInitialInformationFA(QueryTexts, NameOfAccountingObjectTable);
	QueryTextTableTTAccountingFA(QueryTexts, NameOfAccountingObjectTable);
	QueryTextTableTTLocationOfFA(QueryTexts, NameOfAccountingObjectTable);
	
	QueryText = 
	"SELECT
	|	FATable.Ref                            AS Ref,
	|	FATable.FixedAsset                  AS FixedAsset,
	|
	|	AccountingProcedure.FinancialAccountingGroup         AS FinancialAccountingGroup,
	|	AccountingProcedure.LineOfBusiness        AS LineOfBusiness,
	|	AccountingProcedure.RunningTimeValue            AS RunningTimeValue,
	|	AccountingProcedure.EstimatedRunningTime                 AS EstimatedRunningTime,
	|
	|	FALocation.Organization               AS Organization,
	|	FALocation.Leaseholder                 AS Leaseholder,
	|	FALocation.FinanciallyLiablePerson                       AS FinanciallyLiablePerson,
	|	FALocation.FixedAssetsLocation           AS FixedAssetsLocation,
	|	FALocation.LeaseholderBusinessUnit   AS LeaseholderBusinessUnit,
	|	FALocation.LeaseholderEmployeeInCharge             AS LeaseholderEmployeeInCharge,
	|
	|	ISNULL(InitialInformation.CommissioningDateAC, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS RecordInLocalAccounting,
	|	ISNULL(InitialInformation.CommissioningDateMA, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS RecordInManAccounting
	|	
	|INTO TTFAAccountingParameters
	|
	|FROM
	|	Document.FATransfer2_4.FA AS FATable
	|
	|		LEFT JOIN TTInitialInformationFA AS InitialInformation
	|		ON FATable.Ref = InitialInformation.Ref
	|			AND FATable.FixedAsset = InitialInformation.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS AccountingProcedure
	|		ON FATable.Ref = AccountingProcedure.Ref
	|			AND FATable.FixedAsset = AccountingProcedure.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FATable.Ref = FALocation.Ref
	|			AND FATable.FixedAsset = FALocation.FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	
	QueryText = StrReplace(QueryText, "Document.FATransfer2_4.FA", NameOfAccountingObjectTable);
	
	If TempTableName <> Undefined Then
		QueryText = StrReplace(QueryText, "INTO TTFAAccountingParameters", "INTO " + TempTableName);
	EndIf; 
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

// Generates the Query Text of the table in the initial data.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
//  TableName - String -
//	ConsiderCorrections - Boolean -
Procedure QueryTextTableTTInitialInformationFA(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable", TableName = "", ConsiderCorrections = False) Export

	If TableName = "" Then
		TableName = "TTInitialInformationFA";
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFAList(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"InitialFixedAssetsInformation", TableName, "TTFAList", QueryTexts,, ConsiderCorrections);
	
EndProcedure

// Generates the Query Text of the table in the accounting order.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
//  TableName - String -
//	ConsiderCorrections - Boolean -
Procedure QueryTextTableTTAccountingFA(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable", TableName = "", ConsiderCorrections = False) Export

	If TableName = "" Then
		TableName = "TTAccountingFA";
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFAList(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"FixedAssetsAccountingProcedure", TableName, "TTFAList", QueryTexts,, ConsiderCorrections);
	
EndProcedure

// Generates the Query Text of the table in the accounting order.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
//  TableName - String -
//	ConsiderCorrections - Boolean -
Procedure QueryTextTableTueAccountingProcedureForOSBU(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable", TableName = "", ConsiderCorrections = False) Export

	If TableName = "" Then
		TableName = "TueAccountingProcedureForOSBU";
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryTextTableTTFAList(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"AccountingProcedureForOSBU", TableName, "TTFAList", QueryTexts,, ConsiderCorrections);
	
EndProcedure

// Generates the Query Text of the table in the parameters of the ISBU amortization.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
//  TableName - String -
//  ConformityOfMeasurements - Structure - Correspondence of measurements of the main table and register
//	ConsiderCorrections - Boolean -
Procedure QueryTextTableWDepreciationParametersOfOSBU(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable", TableName = "", ConformityOfMeasurements = Undefined, ConsiderCorrections = False) Export

	If TableName = "" Then
		TableName = "WDepreciationParametersOfOSBU";
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryTextTableTTFAList(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"OSBUDepreciationParameters", TableName, "TTFAList", QueryTexts, ConformityOfMeasurements, ConsiderCorrections);
	
EndProcedure

// Generates the Query Text of the table in the order of the account.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
//  TableName - String -
//	ConsiderCorrections - Boolean -
Procedure QueryTextTableTTAccountingProcedureForOsuu(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable", TableName = "", ConsiderCorrections = False) Export

	If TableName = "" Then
		TableName = "TTAccountingProcedureForOsuu";
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFAList(QueryTexts, NameOfAccountingObjectTable);

	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"FixedAssetsAccountingProcedureManagementAccounting", TableName, "TTFAList", QueryTexts,, ConsiderCorrections);
	
EndProcedure

// Generates the Query Text of the vtparametersamortisation table.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
//  TableName - String -
//  ConformityOfMeasurements - Structure - Correspondence of measurements of the main table and register
//	ConsiderCorrections - Boolean -
Procedure QueryTextTableTTOsuuDepreciationParameters(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable", TableName = "", ConformityOfMeasurements = Undefined, ConsiderCorrections = False) Export

	If TableName = "" Then
		TableName = "TTOsuuDepreciationParameters";
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryTextTableTTFAList(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"FixedAssetDepreciationParametersManagementAccounting", TableName, "TTFAList", QueryTexts, ConformityOfMeasurements, ConsiderCorrections);
	
EndProcedure

// Generates the Query Text of the table where the location is.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
Procedure QueryTextTableTTLocationOfFA(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable") Export

	TableName = "TTLocationOfFA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFAList(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"FALocation", TableName, "TTFAList", QueryTexts);
	
EndProcedure

// Generates the Query Text of the table in the leased table.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
Procedure QueryTextTableTTLeasedFA(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable") Export

	TableName = "TTLeasedFA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFAList(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"LeasedAsset", TableName, "TTFAList", QueryTexts);
	
EndProcedure

// Generates the Query Text of the table in the transmitted VENDUOS.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
//  TableName - String -
//	ConsiderCorrections - Boolean -
Procedure QueryTextTableTTLeasedToFA(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable", TableName = "", ConsiderCorrections = False) Export

	If TableName = "" Then
		TableName = "TTLeasedToFA";
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFAList(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"AssetsLeasedOut", TableName, "TTFAList", QueryTexts,, ConsiderCorrections);
	
EndProcedure

// Generates the Query Text of the table in the terms of the lease agreement.
// 
// Parameters:
// 	QueryTexts - ValueList of String - 
Procedure QueryTextTableTTTermsOfLeaseAgreements(QueryTexts) Export
	
	TableName = "TTTermsOfLeaseAgreements";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"TermsOfLeaseContracts", TableName, "DocumentDataDetails", QueryTexts);
	
EndProcedure

// Generates the Query Text of the table in the workingobjects of operation.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
Procedure QueryTextTableTTOperatingTimeOfObjectsOfOperation(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable") Export

	TableName = "TTOperatingTimeOfObjectsOfOperation";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAccountingFA(QueryTexts, NameOfAccountingObjectTable);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	ENDOFPERIOD(DocumentData.Period, MONTH) AS Period,
	|	TTAccountingFA.FixedAsset AS Asset,
	|	TTAccountingFA.RunningTimeValue AS RunningTimeValue
	|
	|INTO OperatingTimeUnitsAreTTIn
	|
	|FROM
	|	TTAccountingFA AS TTAccountingFA
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = TTAccountingFA.Ref
	|
	|INDEX BY
	|	Asset,
	|	RunningTimeValue,
	|	Period
	|";
	
	QueryTexts.Add(QueryText);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"AssetActivityRecords", TableName, "OperatingTimeUnitsAreTTIn", QueryTexts);
	
EndProcedure

// Generates the Query Text of the table in the Components of the amortization nodes.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String -
//
Procedure QueryTextTableTTUnitsDepreciationComponents(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable") Export
	
	TableName = "TTUnitsDepreciationComponents";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTUnitsComponentsOfDepreciationForEntirePeriod(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"SubAssetsComponentsOfDepreciation", TableName, "TTUnitsComponentsOfDepreciationForEntirePeriod", QueryTexts);
	
EndProcedure

// Generates the Query Text of the table in the initial data frame.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
Procedure QueryTextTableTTInitialInformationOfIA(QueryTexts, NameOfAccountingObjectTable = "DocumentDataIATable") Export

	TableName = "TTInitialInformationOfIA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTListOfIa(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"InitialIntangibleAssetsInformation", TableName, "TTListOfIa", QueryTexts);
	
EndProcedure

// Generates the Query Text of the table in the Account parameter.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
//  TempTableName - Undefined - name of the temporary table
Procedure QueryTextTableTTIAAccountingParameters(QueryTexts, NameOfAccountingObjectTable = "DocumentDataIATable", TempTableName = Undefined) Export

	TableName = ?(TempTableName <> Undefined, TempTableName, "TTIAAccountingParameters");
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTListOfIa(QueryTexts, NameOfAccountingObjectTable);
	QueryTextTableTTInitialInformationOfIA(QueryTexts, NameOfAccountingObjectTable);
	QueryTextTableTTAccountingProcedureForIA(QueryTexts, NameOfAccountingObjectTable);
	QueryTextTableTTPlaceOfIaAccounting(QueryTexts, NameOfAccountingObjectTable);
	
	QueryText = 
	"SELECT
	|	TableOfIA.Ref                     AS Ref,
	|	TableOfIA.IntangibleAsset        AS IntangibleAsset,
	|
	|	AccountingProcedure.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	AccountingProcedure.LineOfBusiness  AS LineOfBusiness,
	|	AccountingProcedure.EstimatedRunningTime           AS EstimatedRunningTime,
	|
	|	PlaceOfRegistration.Organization                AS Organization,
	|	PlaceOfRegistration.Department              AS Department,
	|
	|	ISNULL(InitialInformation.DateOfRecognitionAccounting, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS RecordInLocalAccounting,
	|	ISNULL(InitialInformation.DateOfRecognitionManagementAccounting, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS RecordInManAccounting
	|
	|INTO TTIAAccountingParameters
	|
	|FROM
	|	DocumentDataIATable AS TableOfIA
	|
	|		LEFT JOIN TTInitialInformationOfIA AS InitialInformation
	|		ON InitialInformation.Ref = TableOfIA.Ref
	|			AND InitialInformation.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TTAccountingProcedureForIA AS AccountingProcedure
	|		ON AccountingProcedure.Ref = TableOfIA.Ref
	|			AND AccountingProcedure.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|		LEFT JOIN TTPlaceOfIaAccounting AS PlaceOfRegistration
	|		ON PlaceOfRegistration.Ref = TableOfIA.Ref
	|			AND PlaceOfRegistration.IntangibleAsset = TableOfIA.IntangibleAsset
	|
	|INDEX BY
	|	Ref,
	|	IntangibleAsset
	|";
	
	QueryText = StrReplace(QueryText, "Document.IATransfer2_4.IA", NameOfAccountingObjectTable);
	
	If TempTableName <> Undefined Then
		QueryText = StrReplace(QueryText, "INTO TTIAAccountingParameters", "INTO " + TempTableName);
	EndIf; 
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

// Generates the Query Text of the table in the ACCOUNTANMA order.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
Procedure QueryTextTableTTAccountingProcedureForIA(QueryTexts, NameOfAccountingObjectTable = "DocumentDataIATable") Export

	TableName = "TTAccountingProcedureForIA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTListOfIa(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"IntangibleAssetsAccountingProcedure", TableName, "TTListOfIa", QueryTexts);
	
EndProcedure

// Generates the Query Text of the table in the order of the accountanmuu.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
Procedure QueryTextTableTTAccountingProcedureForNMAU(QueryTexts, NameOfAccountingObjectTable = "DocumentDataIATable") Export

	TableName = "TTAccountingProcedureForNMAU";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTListOfIa(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"IntangibleAssetsAccountingProcedureManagementAccounting", TableName, "TTListOfIa", QueryTexts);
	
EndProcedure

// Generates the Query Text of the table in the ACCOUNTANMABU order.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
Procedure QueryTextTableTTAccountingProcedureForNmabu(QueryTexts, NameOfAccountingObjectTable = "DocumentDataIATable") Export

	TableName = "TTAccountingProcedureForNmabu";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTListOfIa(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"IABookkeepingProcedureBookkeepingAndTaxAccounting", TableName, "TTListOfIa", QueryTexts);
	
EndProcedure

// Generates the Query Text of the vtparametersamortizationinmab table.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
Procedure QueryTextTableWDepreciationParametersNMABU(QueryTexts, NameOfAccountingObjectTable = "DocumentDataIATable") Export

	TableName = "WDepreciationParametersNMABU";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTListOfIa(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"IADepreciationParametersBookkeepingAndTaxAccounting", TableName, "TTListOfIa", QueryTexts);
	
EndProcedure

// Generates the Query Text of the vtparametersamortisationinmau table.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
Procedure QueryTextTableTTNmauuDepreciationParameters(QueryTexts, NameOfAccountingObjectTable = "DocumentDataIATable") Export

	TableName = "TTNmauuDepreciationParameters";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTListOfIa(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"IntangibleAssetAmortizationParametersManagementAccounting", TableName, "TTListOfIa", QueryTexts);
	
EndProcedure

// Generates the Query Text of the table in place of the ACCOUNTANMA.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
Procedure QueryTextTableTTPlaceOfIaAccounting(QueryTexts, NameOfAccountingObjectTable = "DocumentDataIATable") Export

	TableName = "TTPlaceOfIaAccounting";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTListOfIa(QueryTexts, NameOfAccountingObjectTable);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"IntangibleAssetsRegistrationPlace", TableName, "TTListOfIa", QueryTexts);
	
EndProcedure

// Generates the Query Text of the Data Processing table.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Object Table Name
Procedure QueryTextTableTTIntangibleAssetsOperatingTime(QueryTexts, NameOfAccountingObjectTable = "DocumentDataIATable") Export
	
	TableName = "TTIntangibleAssetsOperatingTime";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTListOfIa(QueryTexts, NameOfAccountingObjectTable);
	
	QueryText = 
	"SELECT
	|	TTListOfIa.Ref AS Ref,
	|	IntangibleAssetsOperatingTime.IntangibleAsset AS IntangibleAsset,
	|
	|	SUM(IntangibleAssetsOperatingTime.Count) AS Count
	|
	|INTO TTIntangibleAssetsOperatingTime
	|
	|FROM
	|	TTListOfIa AS TTListOfIa
	|	
	|		INNER JOIN AccumulationRegister.IntangibleAssetsOperatingTime AS IntangibleAssetsOperatingTime
	|		ON IntangibleAssetsOperatingTime.Organization = TTListOfIa.Organization
	|			AND IntangibleAssetsOperatingTime.IntangibleAsset = TTListOfIa.IntangibleAsset
	|				AND IntangibleAssetsOperatingTime.Period <= ENDOFPERIOD(TTListOfIa.Period, MONTH)
	|				AND IntangibleAssetsOperatingTime.Active
	|
	|GROUP BY
	|	TTListOfIa.Ref,
	|	IntangibleAssetsOperatingTime.IntangibleAsset
	|
	|INDEX BY
	|	Ref,
	|	IntangibleAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

// Generates the Query Text of the VtSpisokNMA table.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String - Name of the accounting object table.
Procedure QueryTextTableTTListOfIa(QueryTexts, NameOfAccountingObjectTable = "DocumentDataIATable") Export
	
	TableName = "TTListOfIa";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset
	|
	|INTO TTListOfIa
	|
	|FROM
	|	DocumentDataIATable AS TableOfIA
	|	
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = TableOfIA.Ref
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization
	|";
	
	QueryText = StrReplace(QueryText, "DocumentDataIATable", NameOfAccountingObjectTable);
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

// Generates the Query Text of the table in the component nodes of the Amortization period.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String -
//
Procedure QueryTextTableTTUnitsComponentsOfDepreciationForEntirePeriod(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable") Export
	
	TableName = "TTUnitsComponentsOfDepreciationForEntirePeriod";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset AS FixedAsset,
	|	NodesComponents.SubAssetComponent AS SubAssetComponent
	|
	|INTO TTUnitsComponentsOfDepreciationForEntirePeriod
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|	
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS NodesComponents
	|		ON NodesComponents.FixedAsset = FATable.FixedAsset
	|
	|INDEX BY
	|	SubAssetComponent
	|";
	
	QueryText = StrReplace(QueryText, "DocumentDataFATable", NameOfAccountingObjectTable);
	
	QueryTexts.Add(QueryText, TableName, False);

EndProcedure

// Generates the Query Text of the table in the expanded tableos.
// 
// Parameters:
// 	QueryTexts - ValueList of String - 
Procedure QueryTextTableTTExtendedFATable(QueryTexts) Export
	
	RegisterName = "TTExtendedFATable";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTUnitsDepreciationComponents(QueryTexts);
	
	QueryText =
	"SELECT
	|	FATable.Ref              AS Ref,
	|	FATable.FixedAsset    AS FixedAsset,
	|	VALUE(Catalog.Assets.EmptyRef) AS FAOwner,
	|	FATable.RowID AS RowID
	|
	|INTO TTExtendedFATable
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.Ref              AS Ref,
	|	NodesComponents.SubAssetComponent  AS FixedAsset,
	|	FATable.FixedAsset    AS FAOwner,
	|	NodesComponents.RowID AS RowID
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS NodesComponents
	|		ON NodesComponents.Ref = FATable.Ref
	|			AND NodesComponents.FixedAsset = FATable.FixedAsset
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferSubAssets)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";	
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

// Generates the Query Text of the table in the accounting policyfinancial accounting
// 
// Parameters:
// 	QueryTexts - ValueList of String - 
Procedure QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts) Export
	
	TableName = "TTAccountingPolicyOfFinancialAccounting";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	ConformityOfMeasurements = New Structure;
	ConformityOfMeasurements.Insert("Organization", "ParentCompany");
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"FinancialAccountingPolicy", TableName, "DocumentDataDetails", QueryTexts, ConformityOfMeasurements);
	
EndProcedure

// 
// Parameters:
// 	QueryTexts - ValueList of String - 
Procedure QueryTextTableTTTaxSystemSettings(QueryTexts) Export

	TableName = "TTTaxSystemSettings";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	FALSE AS IncomeTaxPayer
	|
	|INTO TTTaxSystemSettings
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|INDEX BY
	|	Ref
	|";
		
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

// Generates the Query Text of the table VT Taxable
// 
// Parameters:
// 	QueryTexts - ValueList of String - 
// 	NameOfAccountingObjectTable - String -
Procedure QueryTextTableTTVATTaxation(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable") Export

	TableName = "TTVATTaxation";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTueAccountingProcedureForOSBU(QueryTexts, NameOfAccountingObjectTable);

	QueryText = 
	"SELECT
	|	AccountingProcedureForOSBU.Ref             AS Ref,
	|	AccountingProcedureForOSBU.FixedAsset   AS FixedAsset,
	|	AccountingProcedureForOSBU.VATTaxation AS VATTaxation
	|
	|INTO TTVATTaxation
	|
	|FROM
	|	TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
		
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

// Generates the Query Text of the VtSostavEGDS table.
// 
// Parameters:
//  QueryTexts - ValueList of String -
//  NameOfAccountingObjectTable - String -
//
Procedure QueryTextTableTTCompositionOfCGU(QueryTexts, NameOfAccountingObjectTable = "DocumentDataFATable") Export
	
	TableName = "TTCompositionOfCGU";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFAList(QueryTexts, NameOfAccountingObjectTable);
	
	ConformityOfMeasurements = New Structure("NonCurrentAsset", "FixedAsset");
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"CGUComposition", TableName, "TTFAList", QueryTexts, ConformityOfMeasurements);
	
EndProcedure

// Generates the Query Text of the table in the empty tableos.
// 
// Parameters:
//  QueryTexts - ValueList of String -
Procedure QueryTextTableTTIsEmptyTableFA(QueryTexts) Export

	TableName = "TTIsEmptyTableFA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT TOP 0
	|	NULL AS Ref,
	|	NULL AS FixedAsset
	|
	|INTO TTIsEmptyTableFA";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

// Generates a request text that receives a cross-section of the last register for documents.
// 
// Parameters:
//  RegisterName - String - The name of the register for which you want to get a slice of the latter.
//  NameOfSliceTable - String - The name of the temporary table that will contain a slice of the latter.
//  ObjectsTableName - String - The name of the temporary table containing the documents (required fields: Registrar, Main means, Date).
//
// Returns:
// 	String - query text.
//
Function RequestTextFARegisterSlice(RegisterName, NameOfSliceTable, ObjectsTableName) Export

	RegisterMetadata = Metadata.InformationRegisters[RegisterName];
	
	ThereIsACompany = False;
	
	FieldList = New Array;
	
	For Each MetadataDimensions In RegisterMetadata.Dimensions Do
		If MetadataDimensions.Name = "Organization" Then
			ThereIsACompany = True;
			Break;
		EndIf; 
	EndDo; 
	
	For Each MetadataDimensions In RegisterMetadata.Resources Do
		PathToField = "	RegisterTable." + MetadataDimensions.Name;
		FieldList.Add(PathToField + " AS " + MetadataDimensions.Name);
	EndDo; 
	
	FieldSeparator = ",
	|	";
	FieldTexts = StrConcat(FieldList, FieldSeparator);
	
	QueryText = 
	"SELECT
	|	TTFATable.Recorder AS Recorder,
	|	TTFATable.Organization AS Organization,
	|	TTFATable.FixedAsset AS FixedAsset,
	|	MAX(RegisterTable.Period) AS Period
	|INTO VT_RegisterName_Period
	|FROM
	|	TT_FATable AS TTFATable
	|
	|		INNER JOIN InformationRegister.InitialFixedAssetsInformation AS RegisterTable
	|		ON RegisterTable.Organization = TTFATable.Organization
	|			AND RegisterTable.FixedAsset = TTFATable.FixedAsset
	|			AND RegisterTable.Period <= TTFATable.Date
	|			AND RegisterTable.CorrectionDate = DATETIME(1,1,1)
	|			AND RegisterTable.Active
	|
	|GROUP BY
	|	TTFATable.Recorder,
	|	TTFATable.Organization,
	|	TTFATable.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterTablePeriod.Recorder AS Recorder,
	|	RegisterTablePeriod.Period AS PeriodOfRegisterTable,
	|	RegisterTablePeriod.Organization AS Organization,
	|	RegisterTablePeriod.FixedAsset AS FixedAsset,
	|	MAX(RegisterTable.Recorder) AS RecorderOfRegisterTable
	|INTO VT_RegistrarName_Registrar
	|FROM
	|	VT_RegisterName_Period AS RegisterTablePeriod
	|
	|		INNER JOIN InformationRegister.InitialFixedAssetsInformation AS RegisterTable
	|		ON RegisterTablePeriod.Organization = RegisterTable.Organization
	|			AND RegisterTablePeriod.FixedAsset = RegisterTable.FixedAsset
	|			AND RegisterTablePeriod.Period = RegisterTable.Period
	|			AND RegisterTable.CorrectionDate = DATETIME(1,1,1)
	|			AND RegisterTable.Active
	|
	|GROUP BY
	|	RegisterTablePeriod.Recorder,
	|	RegisterTablePeriod.Period,
	|	RegisterTablePeriod.Organization,
	|	RegisterTablePeriod.FixedAsset
	|
	|INDEX BY
	|	Recorder,
	|	PeriodOfRegisterTable,
	|	Organization,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterTableRecorder.Recorder AS Recorder,
	|	RegisterTableRecorder.FixedAsset AS FixedAsset,
	|	&FieldTexts
	|
	|INTO VT_RegisterSlice
	|
	|FROM
	|	VT_RegistrarName_Registrar AS RegisterTableRecorder
	|
	|		INNER JOIN InformationRegister.InitialFixedAssetsInformation AS RegisterTable
	|		ON RegisterTable.Organization = RegisterTableRecorder.Organization
	|			AND RegisterTable.FixedAsset = RegisterTableRecorder.FixedAsset
	|			AND RegisterTable.Period = RegisterTableRecorder.PeriodOfRegisterTable
	|			AND RegisterTable.Recorder = RegisterTableRecorder.RecorderOfRegisterTable
	|			AND RegisterTable.CorrectionDate = DATETIME(1,1,1)
	|			AND RegisterTable.Active
	|
	|INDEX BY
	|	Recorder,
	|	FixedAsset";
	
	QueryText = StrReplace(QueryText, "TT_RegisterName", RegisterName);
	QueryText = StrReplace(QueryText, "TT_FATable", ObjectsTableName);
	QueryText = StrReplace(QueryText, "InformationRegister.InitialFixedAssetsInformation", "InformationRegister." + RegisterName);
	QueryText = StrReplace(QueryText, "&FieldTexts", FieldTexts);
	QueryText = StrReplace(QueryText, "VT_RegisterSlice", NameOfSliceTable);
	
	If Not ThereIsACompany Then
		QueryText = StrReplace(QueryText, "RegisterTable.Organization = TTFATable.Organization", "TRUE");
		QueryText = StrReplace(QueryText, "RegisterTablePeriod.Organization = RegisterTable.Organization", "TRUE");
		QueryText = StrReplace(QueryText, "RegisterTable.Organization = RegisterTableRecorder.Organization", "TRUE");
		QueryText = StrReplace(QueryText, "TTFATable.Organization", "UNDEFINED");
		QueryText = StrReplace(QueryText, "RegisterTablePeriod.Organization", "UNDEFINED");
	EndIf; 
		
	If Not RegisterSupportsCorrection(RegisterName) Then
		QueryText = StrReplace(QueryText, "RegisterTable.CorrectionDate = DATETIME(1,1,1)", "TRUE");
	EndIf;

	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

Procedure RegisterCalculationExecutionProblem(Operation, Period, Organization, IssueDetails, ProblemGroup = "", Object = Undefined, Cancel = False) Export

	Cancel = True;
	
	ErrorText = ?(
		ValueIsFilled(IssueDetails), 
		IssueDetails, 
		NStr("vi = 'Khi thực hiện thao tác, đã ghi nhận lỗi';
			|ru = 'При выполнении операции зарегистрированы ошибки';
			|en = 'Errors are registered while executing the operation:'; fa = 'Errors are registered while executing the operation:';
			|it = 'При выполнении операции зарегистрированы ошибки';
			|pl = 'Errors are registered while executing the operation:';
			|tr = 'İşlemin gerçekleştirilmesi sırasında hatalar kaydedildi'"));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeParametersForRegisteringCalculationProblem(
		Operation,
		Organization,
		BegOfMonth(Period));
		
	If Not ValueIsFilled(ProblemGroup) Then
		ProblemGroup = NStr("vi = 'Khi thực hiện thao tác, đã ghi nhận lỗi';
							|ru = 'При выполнении операции зарегистрированы ошибки';
							|en = 'Errors are registered while executing the operation:'; fa = 'Errors are registered while executing the operation:';
							|it = 'При выполнении операции зарегистрированы ошибки';
							|pl = 'Errors are registered while executing the operation:';
							|tr = 'İşlemin gerçekleştirilmesi sırasında hatalar kaydedildi'", Common.DefaultLanguageCode());
	EndIf;
		
	MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
		RegistrationParameters,
		ProblemGroup,
		Enums.AccountingIssueSeverity.Error,
		ErrorText,
		Object);
	
EndProcedure

Procedure RegisterCalculationExecutionWarning(Operation, Period, Organization, WarningDetails, WarningGroup_ = "", Object = Undefined, Cancel = False) Export

	Cancel = True;
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeParametersForRegisteringCalculationProblem(
		Operation,
		Organization,
		BegOfMonth(Period));
		
	If Not ValueIsFilled(WarningGroup_) Then
		WarningGroup_ = NStr("vi = 'Có những cảnh báo trong quá trình hoạt động';
							|ru = 'При выполнении операции возникли предупреждения';
							|en = 'Warnings occurred while executing the operation'; fa = 'Warnings occurred while executing the operation';
							|it = 'Durante l''esecuzione dell''operazione sono stati rilevati degli avvisi';
							|pl = 'Przy wykonaniu operacji wystąpiły ostrzeżenia';
							|tr = 'Operasyon sırasında uyarılar oluştu'", Common.DefaultLanguageCode());
	EndIf;
		
	MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
		RegistrationParameters,
		WarningGroup_,
		Enums.AccountingIssueSeverity.UsefulTip,
		WarningDetails,
		Object);
	
EndProcedure

// Adds a description of the error.
// 
// Parameters:
//  IssueDetails - String -
//  Object - Arbitrary - Object
//  Organization - CatalogRef.Companies - 
//  ErrorList - Array -
Procedure AddErrorDescription(IssueDetails, Object, Organization, ErrorList) Export

	If ErrorList = Undefined Then
		Return;
	EndIf;
	
	ErrorDescription = New Structure;
	ErrorDescription.Insert("IssueDetails", IssueDetails);
	ErrorDescription.Insert("Organization", Organization);
	ErrorDescription.Insert("Object", Object);
	
	ErrorList.Add(ErrorDescription);
	
EndProcedure
 
// Defines the ability to maintain separate accounting of the VNA.
//
// Returns:
//  Boolean - True, if separate accounting is available for VNA.
//
Function ComplianceCAAccountingIsKept() Export

	Return GetFunctionalOption("LocalFAAccounting");
	
EndFunction
 
// Fills in information about the document in another account.
// 
// Parameters:
// 	Object - FormDataStructure - with properties:
// 	           * Ref - DocumentRef -
// 	           * RecordInManAccounting - Boolean -
// 	           * RecordInLocalAccounting - Boolean -
// 	           * DocumentInAnotherAccounting - DocumentRef -
// 	Items - FormAllItems:
//              * DocumentInformationInAnotherAccounting - FormDecoration -  
//              * DecorationDocumentInformationInAnotherAccounting - FormDecoration -  
Procedure FillInInformationAboutDocumentInAnotherAccount(Object, Items) Export

	LabelTitle = DocumentInformationInAnotherAccounting(Object);
	
	If LabelTitle.Count() <> 0 Then
		Items.DocumentInformationInAnotherAccounting.Title = New FormattedString(LabelTitle);
		Items.DecorationDocumentInformationInAnotherAccounting.Visible = True;
		Items.DocumentInformationInAnotherAccounting.Visible = True;
	Else
		Items.DecorationDocumentInformationInAnotherAccounting.Visible = False;
		Items.DocumentInformationInAnotherAccounting.Visible = False;
	EndIf; 

EndProcedure

// LongDesc
// 
// Parameters:
// 	Object - FormDataStructure - with properties:
// 	           * Ref - DocumentRef -
// 	           * RecordInManAccounting - Boolean -
// 	           * RecordInLocalAccounting - Boolean -
// 	           * DocumentInAnotherAccounting - DocumentRef -
// 	ShowInformationIfNotCreated - Boolean - 
// Returns:
// 	Array - LongDesc
Function DocumentInformationInAnotherAccounting(Object, ShowInformationIfNotCreated = True) Export

	LabelTitle = New Array;
	
	If Object.RecordInManAccounting 
		And Object.RecordInLocalAccounting Then
		Return LabelTitle;
	EndIf; 
	
	If ValueIsFilled(Object.DocumentInAnotherAccounting) Then
		
		DocumentAttributes = Common.ObjectAttributesValues(
									Object.DocumentInAnotherAccounting, 
									"RecordInLocalAccounting,RecordInManAccounting,Posted,DeletionMark,Number,Date,Ref");
									
		If Not DocumentAttributes.DeletionMark Then
			LabelTitle = TitleOfCaptionAboutDocumentInAnotherAccount(DocumentAttributes);
		Else
			LabelTitle = FindDocumentInAnotherAccountAndGenerateTitle(Object, ShowInformationIfNotCreated);
		EndIf; 
		
	Else
		
		LabelTitle = FindDocumentInAnotherAccountAndGenerateTitle(Object, ShowInformationIfNotCreated);
		
	EndIf;
	
	Return LabelTitle;
	
EndFunction

Function GetRegulatoryDocument(LinkHeld, LinkNotFound, LinkRemoved, DocumentManager) Export

	If Not ValueIsFilled(LinkHeld)
		And Not ValueIsFilled(LinkNotFound)
		And Not ValueIsFilled(LinkRemoved) Then
		
		DocumentObject = DocumentManager.CreateDocument();
		DocumentObject.Fill(Undefined);
		
	ElsIf ValueIsFilled(LinkHeld) Then
		
		DocumentObject = LinkHeld.GetObject();
		
	ElsIf ValueIsFilled(LinkNotFound) Then
		
		DocumentObject = LinkNotFound.GetObject();
		
	Else
		
		DocumentObject = LinkRemoved.GetObject();
		
	EndIf; 

	Return DocumentObject;
	
EndFunction

// Fills in the signs of reflection in accounting.
// Used in documents that do not contain the option to reflect in accounting.
//
// Parameters:
//  Object			 - DocumentObject	 - The document to fill in the signs of reflection in accounting.
//  ListOfAssets	 - Array			 - List of non-current assets.
//
Procedure FillInReflectionInAccounting(Object, ListOfAssets) Export
	
	Object.RecordInManAccounting = False;
	Object.RecordInLocalAccounting = False;
	
	If ListOfAssets.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(SUM(Recognized_.RecordInManAccounting) > 0, FALSE) AS RecordInManAccounting,
	|	ISNULL(SUM(Recognized_.RecordInLocalAccounting) > 0, FALSE) AS RecordInLocalAccounting
	|
	|FROM
	|	(SELECT TOP 1
	|		0 AS RecordInLocalAccounting,
	|		1 AS RecordInManAccounting
	|	FROM
	|		InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedure
	|	WHERE
	|		FixedAssetsAccountingProcedure.State = VALUE(Enum.FixedAssetsStates.Recognized_)
	|		AND FixedAssetsAccountingProcedure.FixedAsset IN(&ListOfAssets)
	|		AND FixedAssetsAccountingProcedure.Organization = &Organization
	|		AND FixedAssetsAccountingProcedure.Recorder <> &Recorder
	|		AND FixedAssetsAccountingProcedure.Period <= &Date
	|		AND FixedAssetsAccountingProcedure.CorrectionDate = DATETIME(1,1,1)
	|
	|	UNION ALL
	|
	|	SELECT TOP 1
	|		1 AS RecordInLocalAccounting,
	|		0 AS RecordInManAccounting
	|	FROM
	|		InformationRegister.AccountingProcedureForOSBU AS FixedAssetsAccountingProcedure
	|	WHERE
	|		(FixedAssetsAccountingProcedure.BUState IN (
	|				VALUE(Enum.FixedAssetsStates.Recognized_), 
	|				VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting))
	|
	|			OR FixedAssetsAccountingProcedure.StateTa = VALUE(Enum.FixedAssetsStates.Recognized_))
	|
	|		AND FixedAssetsAccountingProcedure.FixedAsset IN(&ListOfAssets)
	|		AND FixedAssetsAccountingProcedure.Organization = &Organization
	|		AND FixedAssetsAccountingProcedure.Recorder <> &Recorder
	|		AND FixedAssetsAccountingProcedure.Period <= &Date
	|		AND FixedAssetsAccountingProcedure.CorrectionDate = DATETIME(1,1,1)
	|
	|	UNION ALL
	|
	|	SELECT TOP 1
	|		0 AS RecordInLocalAccounting,
	|		1 AS RecordInManAccounting
	|	FROM
	|		InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting AS IntangibleAssetsAccountingProcedure
	|	WHERE
	|		IntangibleAssetsAccountingProcedure.State = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting)
	|		AND IntangibleAssetsAccountingProcedure.IntangibleAsset IN(&ListOfAssets)
	|		AND IntangibleAssetsAccountingProcedure.Organization = &Organization
	|		AND IntangibleAssetsAccountingProcedure.Recorder <> &Recorder
	|		AND IntangibleAssetsAccountingProcedure.Period <= &Date
	|
	|	UNION ALL
	|
	|	SELECT TOP 1
	|		1 AS RecordInLocalAccounting,
	|		0 AS RecordInManAccounting
	|	FROM
	|		InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting AS IntangibleAssetsAccountingProcedure
	|	WHERE
	|		(IntangibleAssetsAccountingProcedure.BUState = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting)
	|			OR IntangibleAssetsAccountingProcedure.StateTa = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting))
	|
	|		AND IntangibleAssetsAccountingProcedure.IntangibleAsset IN(&ListOfAssets)
	|		AND IntangibleAssetsAccountingProcedure.Organization = &Organization
	|		AND IntangibleAssetsAccountingProcedure.Recorder <> &Recorder
	|		AND IntangibleAssetsAccountingProcedure.Period <= &Date
	|
	|	) AS Recognized_";
		
	Query = New Query(QueryText);
	Query.SetParameter("ListOfAssets", ListOfAssets);
	Query.SetParameter("Recorder", Object.Ref);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Date", ?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(Object, Selection);
	EndIf;
	
EndProcedure

// Sets the conditional design of elements related to targeted financing.
// 
// Parameters:
// 	ConditionalAppearance - DataCompositionConditionalAppearance - 
// 	Items - FormAllItems:
//				* TargetFinancingExtDimension1 - FormField -  
//				* TargetFinancingExtDimension2 - FormField -  
//				* TargetFinancingExtDimension3 - FormField -  
Procedure EstablishConditionalAppearanceOfTargetedFinancing(ConditionalAppearance, Items) Export
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TargetFinancingExtDimension1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TargetFinancing.ExtDimension1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.TargetFinancing.ExtraDimension1Header"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TargetFinancingExtDimension1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TargetFinancing.ExtraDimension1Allowed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.TargetFinancing.ExtraDimension1Header"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TargetFinancingExtDimension2.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TargetFinancing.ExtDimension2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.TargetFinancing.ExtraDimension2Header"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TargetFinancingExtDimension2.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TargetFinancing.ExtraDimension2Allowed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.TargetFinancing.ExtraDimension2Header"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TargetFinancingExtDimension3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TargetFinancing.ExtDimension3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.TargetFinancing.ExtraDimension3Header"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TargetFinancingExtDimension3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TargetFinancing.ExtraDimension3Allowed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.TargetFinancing.ExtraDimension3Header"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

Function FixedArrayToList(FixedArray) Export

	List = New ValueList;
	For Each ArrayValue In FixedArray Do
		List.Add(ArrayValue);
	EndDo; 
	
	Return List;

EndFunction

// LongDesc
// 
// Parameters:
// 	BusinessTransactionsAndDocuments - See TMCommonUse.NewTableBusinessOperationsAndDocuments
Procedure InitializeBusinessTransactionsAndDocumentsOfNonCurrentAssets(BusinessTransactionsAndDocuments) Export

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	String.FullDocumentName			= Metadata.Documents.InventoryConsumption.FullName();
	String.PurposeUseKey 	= "DomesticConsumption";
	String.WorkplaceTitle	 	= NStr("vi = 'tiêu dùng nội bộ';
										|ru = 'внутренние потребления';
										|en = 'inventory consumptions'; fa = 'inventory consumptions';
										|it = 'Consumo interno';
										|pl = 'Konsumpcje wewnętrzne';
										|tr = 'stok tüketimi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.PurchaseFromSupplier;
	String.FullDocumentName			= Metadata.Documents.VendorInvoiceServicesAndAssets.FullName();
	String.PurposeUseKey 	= "PurchaseFromSupplier";
	String.WorkplaceTitle	 	= NStr("vi = 'mua dịch vụ và các tài sản khác';
										|ru = 'приобретение услуг и прочих активов';
										|en = 'Vendor invoice — Services and Assets'; fa = 'فاکتور تأمین‌کننده — خدمات و دارایی‌ها';
										|it = 'Acquisizione di servizi e altri attivi';
										|pl = 'nabycie usług i innych aktywów';
										|tr = 'satın alma faturası — hizmetler ve varlıklar'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.NonCurrentAssetsSale;
	String.FullDocumentName			= Metadata.Documents.CustomerInvoiceServicesAndAssets.FullName();
	String.PurposeUseKey 	= "NonCurrentAssetsSale";
	String.WorkplaceTitle	 	= NStr("vi = 'bán dịch vụ và các tài sản khác';
										|ru = 'реализация услуг и прочих активов';
										|en = 'Customer invoice — Services and Assets'; fa = 'فاکتور مشتری — خدمات و دارایی‌ها';
										|it = 'Vendita di servizi e altri attivi';
										|pl = 'realizacja usług i innych aktywów';
										|tr = 'müşteri faturası - hizmetler ve varlıklar'");
	String.AddButtonCreate        = True;
	
EndProcedure

Procedure AddFillInCheckResult(Object, AttributeRepresentation, TSName, LineNumber, ProblemObject) Export

	If Not Object.AdditionalProperties.Property("ResultsOfFillingVerification") Then
		Return;
	EndIf;
	
	If Object.AdditionalProperties.ResultsOfFillingVerification = Undefined Then
		Object.AdditionalProperties.ResultsOfFillingVerification = New Array;
	EndIf; 
	
	ResultsOfFillingVerification = Object.AdditionalProperties.ResultsOfFillingVerification; // Array -
	
	ErrorParameters = New Structure;
	ErrorParameters.Insert("Object", ProblemObject);
	ErrorParameters.Insert("AttributeRepresentation", AttributeRepresentation);
	ErrorParameters.Insert("TSName", TSName);
	ErrorParameters.Insert("LineNumber", LineNumber);
	
	ResultsOfFillingVerification.Add(ErrorParameters);
	
EndProcedure

Procedure SetParametersOfSetOfPropertiesInBHA24() Export

	SetPrivilegedMode(True);
	
	UseNonCurrentAssets2_2 = Constants.UseNonCurrentAssets2_2.Get();
	UseNonCurrentAssets2_4 = Constants.UseNonCurrentAssets2_4.Get();
										
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = UseNonCurrentAssets2_4;
	PropertyManager.SetPropertySetParameters("Document_ChangeIntangibleAssetFinancialDetails2_4", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_ChangeFixedAssetFinancialDetails2_4", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_FixedAssetsCostAdditions2_4", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_AllocateVariancesToFixedAssetCost", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_FATransfer2_4", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_PreparingForFixedAssetSale2_4", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_IntangibleAssetsInitialRecognition2_4", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_FixedAssetsInitialRecognition2_4", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_RecognizeSubAssetsComponentsOfDepreciation", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_DisposeIntangibleAssets2_4", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_DisposeFixedAssets2_4", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_IntangibleAssetImprovement", SetParameters);
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = 
		UseNonCurrentAssets2_2
		Or UseNonCurrentAssets2_4;
	PropertyManager.SetPropertySetParameters("Catalog_IntangibleAssets", SetParameters);
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = 
		UseNonCurrentAssets2_2
		Or UseNonCurrentAssets2_4
		Or Constants.UseRMManagement.Get();
	PropertyManager.SetPropertySetParameters("Catalog_Assets_Overall", SetParameters);
	
EndProcedure

Procedure SetValuesOfHoldingParametersWhenMoving(Attributes, ValuesOfHoldingParameters) Export

	If Attributes = Undefined Then
		Return
	EndIf; 
		
	// SenderInformation
	StringPattern = "vi = 'Chuyển từ ""%1""';
					|ru = 'Перемещение из ""%1""';
					|en = 'Transfer from ""%1""';
					|it = 'Spostamento da ""%1""';
					|pl = 'Przenoszenie z ""%1""';
					|tr = '""%1"" den taşıma'"; // @NStr
	If Attributes.BusinessOperation = Enums.BusinessTransactions.TransferOfFixedAssetsToBranchOffice
		Or Attributes.BusinessOperation = Enums.BusinessTransactions.TransferIntangibleAssetsToBranchOffice Then
		
		If Not ValueIsFilled(Attributes.Department)
			Or Not ValueIsFilled(Attributes.Organization) Then
			SenderInformation = "";
		ElsIf Attributes.Department <> Attributes.ReceivingBusinessUnit Then
			StringPattern = "vi = 'Chuyển từ doanh nghiệp ""%1"" và bộ phận ""%2""';
							|ru = 'Перемещение из организации ""%1"" и подразделения ""%2""';
							|en = 'Transfer from the ""%1"" company and the ""%2"" business unit';
							|it = 'Spostamento dall''azienda ""%1"" e reparto ""%2""';
							|pl = 'Przenoszenie z firmy ""%1"" i działu ""%2""';
							|tr = '""%1"" iş yerinden ve ""%2"" departmanından taşıma'"; // @NStr
			SenderInformation = StrTemplate(StringPattern, Attributes.Organization, Attributes.Department);
		Else
			SenderInformation = StrTemplate(StringPattern, Attributes.Organization);
		EndIf; 
		
	ElsIf ValueIsFilled(Attributes.Department) Then
		SenderInformation = StrTemplate(StringPattern, Attributes.Department);
	Else
		SenderInformation = "";
	EndIf;
	ValuesOfHoldingParameters.Insert("SenderInformation", SenderInformation);
	
	// RecipientInformation
	StringPattern = "vi = 'Điều chuyển đến ""%1""';
					|ru = 'Перемещение в ""%1""';
					|en = 'Transfer to ""%1""';
					|it = 'Spostamento in ""%1""';
					|pl = 'Przenoszenie do ""%1""';
					|tr = '""%1"" konumuna taşı'"; // @NStr
	If Attributes.BusinessOperation = Enums.BusinessTransactions.TransferOfFixedAssetsToBranchOffice
		Or Attributes.BusinessOperation = Enums.BusinessTransactions.TransferIntangibleAssetsToBranchOffice Then
		
		If Not ValueIsFilled(Attributes.ReceivingBusinessUnit)
			Or Not ValueIsFilled(Attributes.CompanyRecipient) Then
			RecipientInformation = "";
		ElsIf Attributes.Department <> Attributes.ReceivingBusinessUnit Then
			StringPattern = "vi = 'Chuyển đến doanh nghiệp ""%1"" và bộ phận ""%2""';
							|ru = 'Перемещение в организацию ""%1"" и подразделение ""%2""';
							|en = 'Transfer to the ""%1"" company and the ""%2"" business unit';
							|it = 'Spostamento nell''azienda ""%1"" e reparto ""%2""';
							|pl = 'Przenoszenie do firm ""%1"" i działów ""%2""';
							|tr = '""%1"" iş yerinden ve ""%2"" departmanından taşıma'"; // @NStr
			RecipientInformation = StrTemplate(StringPattern, Attributes.CompanyRecipient, Attributes.ReceivingBusinessUnit);
		Else
			RecipientInformation = StrTemplate(StringPattern, Attributes.CompanyRecipient);
		EndIf; 
		
	ElsIf ValueIsFilled(Attributes.ReceivingBusinessUnit) Then
		RecipientInformation = StrTemplate(StringPattern, Attributes.ReceivingBusinessUnit);
	Else
		RecipientInformation = "";
	EndIf;
	ValuesOfHoldingParameters.Insert("RecipientInformation", RecipientInformation);
	
EndProcedure

// Returns a list of organizations available to the user.
// 
// Returns:
//  Array - A list of organizations available to the user.
//
Function ListOfAllowedOrganizations() Export

	QueryText = 
	"SELECT ALLOWED
	|	Companies.Ref AS Ref
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	NOT Companies.DeletionMark
	|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|";
	
	Query = New Query(QueryText);
	
	CompaniesList = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return CompaniesList;

EndFunction

Function AttributeRepresentation(AttributeName, TSName, PresentationOfDetails, ObjectMetadata) Export

	If PresentationOfDetails = Undefined Then
		PresentationOfDetails = New Map;
		For Each AttributeMetadata In ObjectMetadata.TabularSections[TSName].Attributes Do
			PresentationOfDetails.Insert(AttributeMetadata.Name, AttributeMetadata.Synonym);
		EndDo;
	EndIf;

	Return PresentationOfDetails.Get(AttributeName);
	
EndFunction

Procedure SetVisibilityOfInputCommandBasedOn(Items, DocumentName, CommandsTable, CommandVisibility) Export

	CurRow = CommandsTable.Find("Document." + DocumentName, "Manager");
	If CurRow <> Undefined Then
		Items[CurRow.NameOnForm].Visible = CommandVisibility;
	EndIf;

EndProcedure

// Fills in the prop value or clears it.
// 
// Parameters:
//  Object - DocumentObject - 
//  AttributeName - String - The name of the props
//  Action - String - 
//  Value - Arbitrary -
//  EmptyValue - Arbitrary -
//  ChangedBankingDetails - Array of String -
Procedure FillClearBankingDetails(Object, AttributeName, Action, Value, EmptyValue, ChangedBankingDetails) Export

	If Action = "Fill" 
		And (Not ValueIsFilled(Object[AttributeName])
			Or Object[AttributeName] = False And Value = True) Then
		Object[AttributeName] = Value;
	ElsIf Action = "Clear" Then
		Object[AttributeName] = EmptyValue;
	EndIf;
	
	ChangedBankingDetails.Add(AttributeName);
	
EndProcedure

// Adds the metadata object type by its name.
// 
// Parameters:
//  DocumentName - String - document name
//  CheckForRights - Boolean - Check for rights
//  ListOfObjects - Array -
Procedure AddMetadataObjectType(DocumentName, CheckForRights, ListOfObjects) Export

	If Not CheckForRights Or AccessRight("Posting", Metadata.Documents[DocumentName]) Then
		ListOfObjects.Add(Type("DocumentRef." + DocumentName));
	EndIf; 
	
EndProcedure

Function ThereAreRightsToReadStateOfFA() Export

	Return AccessRight("Read", Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting) 
		And AccessRight("Read", Metadata.InformationRegisters.AccountingProcedureForOSBU);

EndFunction

Function ThereAreRightsToReadStateOfIA() Export

	Return AccessRight("Read", Metadata.InformationRegisters.IntangibleAssetsAccountingProcedureManagementAccounting) 
		And NonCurrentAssetsLocalization.ThereAreRightsToReadStateOfIA();

EndFunction

Function SumPresentation_(Sum, AmountHeader, Currency) Export

	SumByLine = Format(Sum, "NFD=2; NZ=-; NG=3,0");
	
	SumPresentation_ = New Array;
	
	If Sum > 0 Then
		
		Text = StrTemplate("%1 %2 %3", AmountHeader, SumByLine, Currency);
		SumPresentation_.Add(Text);
		
	ElsIf Sum < 0 Then
		
		SumPresentation_.Add(AmountHeader);
		SumPresentation_.Add(" ");
		SumPresentation_.Add(New FormattedString(SumByLine,, StyleColors.NegativeTextColor));
		SumPresentation_.Add(" ");
		SumPresentation_.Add(String(Currency));
		
	Else
		
		SumPresentation_.Add(AmountHeader + " -");
		
	EndIf; 

	Return New FormattedString(SumPresentation_);
	
EndFunction

Procedure SetStructureProperty(PropertyName, PropertyValue, Receiver) Export

	PathToProperty = StrSplit(PropertyName, ".");
	
	If TypeOf(Receiver) = Type("FixedStructure")
		Or Receiver = Undefined Then
		
		NewProperties = New Structure(Receiver);

		If PathToProperty.Count() = 3 Then
			NewProperties[PathToProperty[0]][PathToProperty[1]].Insert(PathToProperty[2], PropertyValue);
		ElsIf PathToProperty.Count() = 2 Then
			NewProperties[PathToProperty[0]].Insert(PathToProperty[1], PropertyValue);
		Else
			NewProperties.Insert(PropertyName, PropertyValue);
		EndIf;
		
		Receiver = New FixedStructure(NewProperties);
		
	Else

		If PathToProperty.Count() = 3 Then
			Receiver[PathToProperty[0]][PathToProperty[1]].Insert(PathToProperty[2], PropertyValue);
		ElsIf PathToProperty.Count() = 2 Then
			Receiver[PathToProperty[0]].Insert(PathToProperty[1], PropertyValue);
		Else
			Receiver.Insert(PropertyName, PropertyValue);
		EndIf;

	EndIf;
	
EndProcedure

Function AvailableSelectionOfObjectsOfOperation2_4(Parameters) Export

	If Not GetFunctionalOption("UseNonCurrentAssets2_4") Then
		Return False;
	EndIf;
	
	If Parameters.Property("Context") 
		And StrFind(Parameters.Context, "MA") = 0
		And StrFind(Parameters.Context, "UR") = 0 Then
		
		ChoiceAvailable = False;
		
	ElsIf GetFunctionalOption("UseNonCurrentAssets2_2") Then
	
		AccountingStartDate = NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24();
		
		ChoiceAvailable = 
			Parameters.Property("Context") 
				And StrFind(Parameters.Context, "MFP") = 0
			Or Not Parameters.Property("DateOfLastEdit")
				And CurrentSessionDate() >= AccountingStartDate 
			Or Parameters.Property("DateOfLastEdit")
				And Parameters.DateOfLastEdit >= AccountingStartDate;
	Else
		ChoiceAvailable = True;
	EndIf;
			
	If Not ChoiceAvailable Then
		Return False;
	EndIf;
	
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("Busstate") Then
			Parameters.Insert("State", Parameters.Filter.Busstate);
		EndIf; 
		If Parameters.Filter.Property("Buorganization") Then
			Parameters.Filter.Insert("Organization", Parameters.Filter.Buorganization);
		EndIf; 
		If Parameters.Filter.Property("Bupodispartion") Then
			Parameters.Filter.Insert("Department", Parameters.Filter.Bupodispartion);
		EndIf; 
	EndIf; 
	
	Return True;

EndFunction

Procedure CheckComplianceOfExpenseItemWithAccountingProcedureTa(Form) Export

	Object = Form.Object;
	
	If Not ValueIsFilled(Object.ExpenseItemTaxAccounting) Then
		Return;
	EndIf;
	
	ArrayOfDistributionOptions = NonCurrentAssetsClientServer.AvailableCostSharingOptions(Object.AccountingProcedureTA);
		
	If ArrayOfDistributionOptions.Count() = 0 Then
		Return;
	EndIf;
	
	CostAllocationOptionLocal = Common.ObjectAttributeValue(Object.ExpenseItemTaxAccounting, "CostAllocationOptionTax");
	
	If ArrayOfDistributionOptions.Find(CostAllocationOptionLocal) = Undefined Then
		Object.ExpenseItemTaxAccounting = Undefined;
		Object.ExpensesDimensionTaxAccounting = Undefined;
		Form.ExpensesDimensionTaxAccountingRequired_ = False;
	EndIf;
	
EndProcedure

// Fills in the details of the document header for the location of fixed assets.
// 
// Parameters:
// 	ListOrStructureOfDetails	- String, Structure	-	Details that need to be filled.
// 															The structure key stores the name of the document's details.
// 															The value is stored
// 	TabularSection	-	FormDataCollection	-	Table part where fixed assets are specified.
// 	Object	-	FormDataStructure	- Document data.
// 	ChangedBankingDetails	-	String	-	List of changed Bank details.
//
Procedure FillInHeaderForSelectedFA(ListOrStructureOfDetails, TabularSection, Object, ChangedBankingDetails = Undefined) Export
	
	If TabularSection <> Undefined And TabularSection.Count() = 0
		Or TabularSection = Undefined And Not ValueIsFilled(Object.FixedAsset) Then
		Return;
	EndIf;
	
	If TypeOf(ListOrStructureOfDetails) = Type("String") Then
		AttributesStructure1 = New Structure(ListOrStructureOfDetails);
	Else
		AttributesStructure1 = ListOrStructureOfDetails;
	EndIf;

	FillPropertyValues(AttributesStructure1, Object);
	
	ThereAreBlankDetails = False;
	For Each KeyAndValue In AttributesStructure1 Do
		If Not ValueIsFilled(KeyAndValue.Value) Then
			ThereAreBlankDetails = True;
			Break;
		EndIf;
	EndDo;
	
	If Not ThereAreBlankDetails Then
		Return;
	EndIf;

	If TabularSection <> Undefined Then
		FixedAsset = FirstFilledValueInTable(TabularSection, "FixedAsset");
	Else
		FixedAsset = Object.FixedAsset;
	EndIf;
	
	If Not ValueIsFilled(FixedAsset) Then
		Return;
	EndIf;
	
	FALocation = NonCurrentAssets.FALocation(FixedAsset, Object.Date);
	
	If ChangedBankingDetails <> Undefined Then
		ChangedBankDetails = StrSplit(ChangedBankingDetails, ",");
	Else
		ChangedBankDetails = New Array;
	EndIf;
	
	If AttributesStructure1.Property("Organization")
		And Not ValueIsFilled(Object.Organization) Then
		Object.Organization = FALocation.Organization;
		ChangedBankDetails.Add("Organization");
	EndIf;
	
	If AttributesStructure1.Property("Department")
		And Not ValueIsFilled(Object.Department) Then
		Object.Department = FALocation.FixedAssetsLocation;
		ChangedBankDetails.Add("Department");
	EndIf;
	
	If AttributesStructure1.Property("FINANCIALLYLIABLEPERSON")
		And Not ValueIsFilled(Object.FinanciallyLiablePerson) Then
		Object.FinanciallyLiablePerson = FALocation.FinanciallyLiablePerson;
		ChangedBankDetails.Add("FINANCIALLYLIABLEPERSON");
	EndIf;
	
	If ChangedBankingDetails <> Undefined Then
		ChangedBankingDetails = StrConcat(ChangedBankDetails, ",");
	EndIf;
	
EndProcedure

// Fills in the details of the document header for the location of fixed assets.
// 
// Parameters:
// 	ListOrStructureOfDetails	- String, Structure	-	Details that need to be filled.
// 															The structure key stores the name of the document's details.
// 															The value is stored
// 	TabularSection	-	FormDataCollection	-	Table part where fixed assets are specified.
// 	Object	-	FormDataStructure	- Document data.
// 	ChangedBankingDetails	-	String	-	List of changed Bank details.
//
Procedure FillInHeaderForSelectedIA(ListOrStructureOfDetails, TabularSection, Object, ChangedBankingDetails = Undefined) Export
	
	If TabularSection <> Undefined And TabularSection.Count() = 0
		Or TabularSection = Undefined And Not ValueIsFilled(Object.FixedAsset) Then
		Return;
	EndIf;
	
	If TypeOf(ListOrStructureOfDetails) = Type("String") Then
		AttributesStructure1 = New Structure(ListOrStructureOfDetails);
	Else
		AttributesStructure1 = ListOrStructureOfDetails;
	EndIf;

	FillPropertyValues(AttributesStructure1, Object);
	
	ThereAreBlankDetails = False;
	For Each KeyAndValue In AttributesStructure1 Do
		If Not ValueIsFilled(KeyAndValue.Value) Then
			ThereAreBlankDetails = True;
			Break;
		EndIf;
	EndDo;
	
	If Not ThereAreBlankDetails Then
		Return;
	EndIf;

	If TabularSection <> Undefined Then
		IntangibleAsset = FirstFilledValueInTable(TabularSection, "IntangibleAsset");
	Else
		IntangibleAsset = Object.IntangibleAsset;
	EndIf;
	
	If Not ValueIsFilled(IntangibleAsset) Then
		Return;
	EndIf;
	
	IntangibleAssetsRegistrationPlace = NonCurrentAssets.IntangibleAssetsRegistrationPlace(IntangibleAsset);
	
	If ChangedBankingDetails <> Undefined Then
		ChangedBankDetails = StrSplit(ChangedBankingDetails, ",");
	Else
		ChangedBankDetails = New Array;
	EndIf;
	
	If AttributesStructure1.Property("Organization")
		And Not ValueIsFilled(Object.Organization) Then
		Object.Organization = IntangibleAssetsRegistrationPlace.Organization;
		ChangedBankDetails.Add("Organization");
	EndIf;
	
	If AttributesStructure1.Property("Department")
		And Not ValueIsFilled(Object.Department) Then
		Object.Department = IntangibleAssetsRegistrationPlace.Department;
		ChangedBankDetails.Add("Department");
	EndIf;
	
	If AttributesStructure1.Property("ExpensesPostingMethod") Then
		
		ReflectionInAccounting_ = New Structure("RecordInLocalAccounting,RecordInManAccounting", Undefined, Undefined);
		FillPropertyValues(ReflectionInAccounting_, Object);
		
		WaysToReflectExpenses = IAExpensesRecordingMethods(Object.Date, IntangibleAsset, Object.Organization);
		
		If ReflectionInAccounting_.RecordInManAccounting = True
			And ValueIsFilled(WaysToReflectExpenses.MethodOfReflectingDepreciationOfMA) Then
			
			Object.ExpensesPostingMethod = WaysToReflectExpenses.MethodOfReflectingDepreciationOfMA;
			ChangedBankDetails.Add("ExpensesPostingMethod");
			
		ElsIf ReflectionInAccounting_.RecordInLocalAccounting = True
			And ValueIsFilled(WaysToReflectExpenses.DepreciationRecordMethodLA) Then
			
			Object.ExpensesPostingMethod = WaysToReflectExpenses.DepreciationRecordMethodLA;
			ChangedBankDetails.Add("ExpensesPostingMethod");
			
		ElsIf ReflectionInAccounting_.RecordInLocalAccounting = True
			And ValueIsFilled(WaysToReflectExpenses.DepreciationRecordMethodTA) Then
			
			Object.ExpensesPostingMethod = WaysToReflectExpenses.DepreciationRecordMethodTA;
			ChangedBankDetails.Add("ExpensesPostingMethod");
			
		EndIf;
		
	EndIf;
	
	If ChangedBankingDetails <> Undefined Then
		ChangedBankingDetails = StrConcat(ChangedBankDetails, ",");
	EndIf;
	
EndProcedure

// Fills in the details of the document header for the location of leased fixed assets.
// 
// Parameters:
// 	AttributesList - String - Details that need to be filled.
// 	TabularSection - FormDataCollection - Table part where fixed assets are specified.
// 	Object - FormDataStructure - Document data.
// 	ChangedBankingDetails	- String - List of changed Bank details.
//
Procedure FillInHeaderForLeasedFA(AttributesList, TabularSection, Object, ChangedBankingDetails = Undefined) Export
	
	If TabularSection <> Undefined And TabularSection.Count() = 0
		Or TabularSection = Undefined And Not ValueIsFilled(Object.FixedAsset) Then
		Return;
	EndIf;
	
	AttributesStructure1 = New Structure(AttributesList);

	FillPropertyValues(AttributesStructure1, Object);
	
	ThereAreBlankDetails = False;
	For Each KeyAndValue In AttributesStructure1 Do
		If Not ValueIsFilled(KeyAndValue.Value) Then
			ThereAreBlankDetails = True;
			Break;
		EndIf;
	EndDo;
	
	If Not ThereAreBlankDetails Then
		Return;
	EndIf;

	FixedAsset = Undefined;
	
	If TabularSection <> Undefined Then
		For Each RowData In TabularSection Do
			If ValueIsFilled(RowData.FixedAsset) Then
				FixedAsset = RowData.FixedAsset;
				Break;
			EndIf;
		EndDo;
	Else
		FixedAsset = Object.FixedAsset;
	EndIf;
	
	If Not ValueIsFilled(FixedAsset) Then
		Return;
	EndIf;
	
	FALocation = NonCurrentAssets.LocationAndLandlordFA(FixedAsset);
	
	If ChangedBankingDetails <> Undefined Then
		ChangedBankDetails = StrSplit(ChangedBankingDetails, ",");
	Else
		ChangedBankDetails = New Array;
	EndIf;
	
	If AttributesStructure1.Property("Organization")
		And Not ValueIsFilled(Object.Organization) Then
		Object.Organization = FALocation.Organization;
		ChangedBankDetails.Add("Organization");
	EndIf;
	
	If AttributesStructure1.Property("Partner")
		And Not ValueIsFilled(Object.Partner) Then
		Object.Partner = FALocation.Partner;
		ChangedBankDetails.Add("Partner");
	EndIf;
	
	If AttributesStructure1.Property("Counterparty")
		And Not ValueIsFilled(Object.Counterparty) Then
		Object.Counterparty = FALocation.Counterparty;
		ChangedBankDetails.Add("Counterparty");
	EndIf;
	
	If AttributesStructure1.Property("Contract")
		And Not ValueIsFilled(Object.Contract) Then
		Object.Contract = FALocation.Contract;
		ChangedBankDetails.Add("Contract");
	EndIf;
	
	If AttributesStructure1.Property("Department")
		And Not ValueIsFilled(Object.Department) Then
		Object.Department = FALocation.FixedAssetsLocation;
		ChangedBankDetails.Add("Department");
	EndIf;
	
	If AttributesStructure1.Property("FINANCIALLYLIABLEPERSON")
		And Not ValueIsFilled(Object.FinanciallyLiablePerson) Then
		Object.FinanciallyLiablePerson = FALocation.FinanciallyLiablePerson;
		ChangedBankDetails.Add("FINANCIALLYLIABLEPERSON");
	EndIf;
	
	If ChangedBankingDetails <> Undefined Then
		ChangedBankingDetails = StrConcat(ChangedBankDetails, ",");
	EndIf;
	
EndProcedure

// A way to reflect FA expenses.
// 
// Parameters:
//  Object - DocumentObject - Document
//  FixedAsset - CatalogRef.Assets - The main means
// 
// Returns:
//  CatalogRef.WaysToReflectExpenses - The way expenses are reflected
//
Function WayToReflectFAExpenses(Object, FixedAsset) Export
	
	If Not ValueIsFilled(FixedAsset) Then
		Return Undefined;
	EndIf;

	ReflectionInAccounting_ = New Structure("RecordInLocalAccounting,RecordInManAccounting", Undefined, Undefined);
	FillPropertyValues(ReflectionInAccounting_, Object);
	
	WaysToReflectExpenses = FAExpensesRecordingMethods(Object.Date, FixedAsset, Object.Organization);
	
	If ReflectionInAccounting_.RecordInManAccounting = True
		And ValueIsFilled(WaysToReflectExpenses.MethodForReflectingMaExpenses) Then
		
		ExpensesPostingMethod = WaysToReflectExpenses.MethodForReflectingMaExpenses;
		
	ElsIf ReflectionInAccounting_.RecordInLocalAccounting = True
		And ValueIsFilled(WaysToReflectExpenses.ExpenseRecordMethodAC) Then
		
		ExpensesPostingMethod = WaysToReflectExpenses.ExpenseRecordMethodAC;
		
	ElsIf ReflectionInAccounting_.RecordInLocalAccounting = True
		And ValueIsFilled(WaysToReflectExpenses.ExpenseRecordMethodTA) Then
		
		ExpensesPostingMethod = WaysToReflectExpenses.ExpenseRecordMethodTA;
		
	EndIf;

	Return ExpensesPostingMethod;
		
EndFunction

// A way to reflect FA expenses.
// 
// Parameters:
//  Object - DocumentObject - Document
//  IntangibleAsset - CatalogRef.IntangibleAssets - Intangible asset
// 
// Returns:
//  CatalogRef.WaysToReflectExpenses - The way expenses are reflected
//
Function WayToReflectIAExpenses(Object, IntangibleAsset) Export
	
	If Not ValueIsFilled(IntangibleAsset) Then
		Return Undefined;
	EndIf;

	ReflectionInAccounting_ = New Structure("RecordInLocalAccounting,RecordInManAccounting", Undefined, Undefined);
	FillPropertyValues(ReflectionInAccounting_, Object);
	
	WaysToReflectExpenses = IAExpensesRecordingMethods(Object.Date, IntangibleAsset, Object.Organization);
	
	If ReflectionInAccounting_.RecordInManAccounting = True
		And ValueIsFilled(WaysToReflectExpenses.MethodForReflectingMaExpenses) Then
		
		ExpensesPostingMethod = WaysToReflectExpenses.MethodForReflectingMaExpenses;
		
	ElsIf ReflectionInAccounting_.RecordInLocalAccounting = True
		And ValueIsFilled(WaysToReflectExpenses.ExpenseRecordMethodAC) Then
		
		ExpensesPostingMethod = WaysToReflectExpenses.ExpenseRecordMethodAC;
		
	ElsIf ReflectionInAccounting_.RecordInLocalAccounting = True
		And ValueIsFilled(WaysToReflectExpenses.ExpenseRecordMethodTA) Then
		
		ExpensesPostingMethod = WaysToReflectExpenses.ExpenseRecordMethodTA;
		
	EndIf;

	Return ExpensesPostingMethod;
		
EndFunction

// Checks the start date of the parameters.
// 
// Parameters:
// 	Object - DocumentObject - The document for which the date is being checked.
// 	Cancel - Boolean - True if the check failed.
Procedure CheckStartOfParameters(Object, Cancel) Export
	
	If Not Object.AdjustmentModeFromPreviousDate
		Or Not ValueIsFilled(Object.ValidOnDate) Then
		Return
	EndIf;
	
	If Object.ValidOnDate >= BegOfMonth(Object.Date)
		And ValueIsFilled(Object.Date) Then
		MessageText = NStr("vi = 'Thời gian bắt đầu có hiệu lực của tham số phải sớm hơn đầu tháng lập chứng từ';
							|ru = 'Начало действия параметров должно быть раньше начала месяца, в котором оформлен документ';
							|en = 'The parameter start must be earlier than the beginning of the month in which the document is created'; fa = 'The parameter start must be earlier than the beginning of the month in which the document is created';
							|it = 'L''inizio dell''azione dei parametri deve essere precedente all''inizio del mese nel quale è stato registrato il documento';
							|pl = 'Wejście w życie parametrów powinno być wcześniej niż początek miesiąca, w którym jest utworzony dokument';
							|tr = 'Parametrelerin başlangıcı, belgenin düzenlendiği ayın başından önce olmalıdır'");
		Common.MessageToUser(MessageText, Object, "ValidOnDate",, Cancel);
	ElsIf Not NonCurrentAssets.VNAManagementIsUsed_2_4(Object.ValidOnDate) Then
		MessageText = NStr("vi = 'Thời gian bắt đầu có hiệu lực của tham số không được sớm hơn khi bắt đầu hạch toán tài sản dài hạn phiên bản 2.4';
							|ru = 'Начало действия параметров должно быть не раньше начала учета внеоборотных активов версии 2.4';
							|en = 'The financial details start must not be earlier than the start of fixed and intangible assets accounting version 2.4'; fa = 'The financial details start must not be earlier than the start of fixed and intangible assets accounting version 2.4';
							|it = 'L''inizio dell''azione dei parametri non deve essere precedente all''inizio della contabilità degli attivi non correnti della versione 2.4';
							|pl = 'Wejście w życie parametrów powinno być nie wcześniej niż początek ewidencji aktywów nieobrotowych wersji 2.4';
							|tr = 'Parametrelerin başlangıcı, duran varlıkların muhasebeleştirilmesinin başlamasından daha erken olmamalıdır sürüm 2.4'");
		Common.MessageToUser(MessageText, Object, "ValidOnDate",, Cancel);
	EndIf;
	
EndProcedure

// Returns the first filled field value in the table.
// 
// Parameters:
//  Table - TabularSection - Table
//  Field - String - Field
//  EmptyValue - AnyRef, Undefined - 
// 
// Returns:
//  Undefined, AnyRef - The first filled field value in the table
//
Function FirstFilledValueInTable(Table, Field, EmptyValue = Undefined) Export
	
	Value = EmptyValue;
	
	For Each RowData In Table Do
		If ValueIsFilled(RowData[Field]) Then
			Value = RowData[Field];
			Break;
		EndIf;
	EndDo;

	Return Value;
		
EndFunction

// the selection parameters.
// 
// Parameters:
//  ChoiceParameters - FixedArray of ChoiceParameter - The selection parameters
//  ExcludeElement - String - parameter name
// 
// Returns:
//  Array of ChoiceParameter - The selection parameters
Function ChoiceParameters(ChoiceParameters, ExcludeElement) Export

	NewSelectionOptions = New Array;
	For Each Item In ChoiceParameters Do
		If Upper(Item.Name) <> Upper(ExcludeElement) Then
			NewSelectionOptions.Add(Item);
		EndIf;
	EndDo;
	
	Return NewSelectionOptions;
	
EndFunction

// Converts the value to an array.
// 
// Parameters:
//  Value - Array, ValueList - Value
// 
// Returns:
//  Array - Value converted to an array
Function ValueToArray(Val Value) Export
	
	If TypeOf(Value) = Type("Array") Then
				
		Result = Value;
			
	ElsIf TypeOf(Value) = Type("FixedArray") Then
			
		Result = New Array(Value);
			
	ElsIf TypeOf(Value) = Type("ValueList") Then
			
		Result = Value.UploadValue();
				
	Else
				
		Result = New Array;
		Result.Add(Value);
		
	EndIf;
				
	Return Result;
		
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Recognition

// 
// Parameters:
//  ListOfMergeRequests - Array of String -
//
Procedure TextOfRequestOtherexpensesOfAcceptanceForAccounting(ListOfMergeRequests) Export
	
	QueryText = NonCurrentAssetsLocalization.TextOfRequestOtherexpensesOfAcceptanceForAccounting(ListOfMergeRequests);
	
	If QueryText <> Undefined Then
		ListOfMergeRequests.Add(QueryText);
		Return;
	EndIf;
	
	ListOfRequests = New Array;
	
	#Region Recognition // - Cr 08
	
	QueryText =
	"SELECT
	|	DocumentData.Period                       AS Period,
	|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
	|	DocumentData.Organization                  AS Organization,
	|	TTCostCalculation.Department              AS Department,
	|	TTCostCalculation.ExpenseItem             AS ExpenseItem,
	|	TTCostCalculation.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TTCostCalculation.LineOfBusiness    AS LineOfBusiness,
	|	UNDEFINED                                 AS VATActivityType,
	|
	|	CASE
	|		WHEN DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|				OR NOT DocumentData.RecordInManAccounting
	|			THEN 0
	|		ELSE TTCostCalculation.Sum
	|	END AS AmountIncludingVAT,
	|
	|	CASE
	|		WHEN DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|				OR NOT DocumentData.RecordInManAccounting
	|			THEN 0
	|		ELSE TTCostCalculation.AmountExcludingVAT
	|	END AS AmountExcludingVAT,
	|
	|	CASE
	|		WHEN DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|				OR NOT DocumentData.RecordInManAccounting
	|			THEN 0
	|		ELSE TTCostCalculation.AmountOfUU
	|	END AS AmountExcludingVATMan,
	|
	|	CASE
	|		WHEN DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|				OR DocumentData.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|				OR NOT DocumentData.PostInAccounting
	|			THEN 0
	|		ELSE TTCostCalculation.AmountAccounting + TTCostCalculation.CFAmount
	|	END AS AmountIncludingVATCompl,
	|
	|	CASE
	|		WHEN DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|				OR DocumentData.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|				OR NOT DocumentData.PostInAccounting
	|			THEN 0
	|		ELSE TTCostCalculation.AmountAccounting + TTCostCalculation.CFAmount
	|	END AS AmountExcludingVATCompl,
	|
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	DocumentData.BusinessOperation        AS BusinessOperation,
	|	UNDEFINED                                 AS ItemsLocationAttributes,
	|	                                                                             
	|	TTCostCalculation.RowID        AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting,
	|
	|	DocumentData.Ref                       AS Recorder,
	|	TTCostCalculation.VariancePeriod           AS VariancePeriod
	|
	|	,0 AS AITAmount
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = DocumentData.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|		OR DocumentData.PostInAccounting
	|			AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|			AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses))
	|";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
	
	ListOfMergeRequests.Add(QueryText);
	
EndProcedure

// 
// Parameters:
//  ListOfMergeRequests - Array of String -
//  ThereIsAccountingProcedureForMA - Boolean -
//  ThereIsAccountingProcedureForAC - Boolean -
//  ThereIsAccountingProcedureWELL - Boolean -
//
Procedure QueryTextOfOtherExpensesShouldNotBeTakenIntoAccountAndIncludedInExpenses(ListOfMergeRequests, ThereIsAccountingProcedureForMA = True, ThereIsAccountingProcedureForAC = True, ThereIsAccountingProcedureWELL = True) Export
	
	QueryText = NonCurrentAssetsLocalization.QueryTextOfOtherExpensesShouldNotBeTakenIntoAccountAndIncludedInExpenses(ThereIsAccountingProcedureForMA, ThereIsAccountingProcedureForAC, ThereIsAccountingProcedureWELL);
	
	If QueryText <> Undefined Then
		ListOfMergeRequests.Add(QueryText);
		Return;
	EndIf;
	
	ListOfRequests = New Array;
	
	If ThereIsAccountingProcedureForMA Then
		
		QueryText =
		"SELECT
		|	DocumentData.Period                       AS Period,
		|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
		|	DocumentData.Organization                  AS Organization,
		|	TTCostCalculation.Department              AS Department,
		|	TTCostCalculation.ExpenseItem             AS ExpenseItem,
		|	TTCostCalculation.DimensionOfExpenses          AS DimensionOfExpenses,
		|	TTCostCalculation.LineOfBusiness    AS LineOfBusiness,
		|	UNDEFINED                                 AS VATActivityType,
		|
		|	TTCostCalculation.Sum AS AmountIncludingVAT,
		|	TTCostCalculation.AmountExcludingVAT AS AmountExcludingVAT,
		|	TTCostCalculation.AmountOfUU AS AmountExcludingVATMan,
		|
		|	0 AS AmountIncludingVATCompl,
		|	0 AS AmountExcludingVATCompl,
		|
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|
		|	&Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount AS BusinessOperation,
		|	UNDEFINED                                   AS ItemsLocationAttributes,
		|	                                                                             
		|	TTCostCalculation.RowID        AS FinRecordID,
		|	&SettingUpHo_WriteOffOfCostsForExpensesWithoutTakingThemIntoAccount AS BusinessTransactionSetting,
		|
		|	DocumentData.Ref                       AS Recorder,
		|	TTCostCalculation.VariancePeriod           AS VariancePeriod
		|
		|	,0 AS AITAmount
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTCostCalculation AS TTCostCalculation
		|		ON TTCostCalculation.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Period                       AS Period,
		|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
		|	DocumentData.Organization                  AS Organization,
		|
		|   CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
		|			THEN DocumentData.FixedAssetsLocation
		|		ELSE DocumentData.BusinessUnitManagementAccounting
		|	END AS Department,
		|
		|	DocumentData.ExpenseItemManagementAccounting             AS ExpenseItem,
		|	DocumentData.ExpensesDimensionManagementAccounting          AS DimensionOfExpenses,
		|
		|	CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
		|			THEN DocumentData.LineOfBusiness
		|		ELSE DocumentData.LineOfBusinessManagementAccounting
		|	END AS LineOfBusiness,
		|
		|	UNDEFINED                                 AS VATActivityType,
		|
		|	TTCostCalculation.Sum AS AmountIncludingVAT,
		|	TTCostCalculation.AmountExcludingVAT AS AmountExcludingVAT,
		|	TTCostCalculation.AmountOfUU AS AmountExcludingVATMan,
		|
		|	0 AS AmountIncludingVATCompl,
		|	0 AS AmountExcludingVATCompl,
		|
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|
		|	&Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount AS BusinessOperation,
		|	UNDEFINED                                 AS ItemsLocationAttributes,
		|	                                                                             
		|	TTCostCalculation.RowID        AS FinRecordID,
		|	&SettingUpHo_WriteOffOfCostsForExpensesWithoutTakingThemIntoAccount AS BusinessTransactionSetting,
		|
		|	DocumentData.Ref                       AS Recorder,
		|	TTCostCalculation.VariancePeriod           AS VariancePeriod
		|
		|	,0 AS AITAmount
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTCostCalculation AS TTCostCalculation
		|		ON TTCostCalculation.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|
		|";
	
		ListOfRequests.Add(QueryText);
	
	EndIf;
	
	If ThereIsAccountingProcedureForAC Then
		
		QueryText =
		"SELECT
		|	DocumentData.Period                       AS Period,
		|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
		|	DocumentData.Organization                  AS Organization,
		|	TTCostCalculation.Department              AS Department,
		|	TTCostCalculation.ExpenseItem             AS ExpenseItem,
		|	TTCostCalculation.DimensionOfExpenses          AS DimensionOfExpenses,
		|	TTCostCalculation.LineOfBusiness    AS LineOfBusiness,
		|	UNDEFINED                                 AS VATActivityType,
		|
		|	0 AS AmountIncludingVAT,
		|	0 AS AmountExcludingVAT,
		|	0 AS AmountExcludingVATMan,
		|
		|	TTCostCalculation.AmountAccounting AS AmountIncludingVATCompl,
		|	TTCostCalculation.AmountAccounting AS AmountExcludingVATCompl,
		|
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|
		|	&Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount AS BusinessOperation,
		|	UNDEFINED                                 AS ItemsLocationAttributes,
		|	                                                                             
		|	TTCostCalculation.IdOfACLine      AS FinRecordID,
		|	&SettingUpHo_WriteOffOfCostsForExpensesWithoutTakingThemIntoAccount AS BusinessTransactionSetting,
		|
		|	DocumentData.Ref                       AS Recorder,
		|	TTCostCalculation.VariancePeriod           AS VariancePeriod
		|
		|	,0 AS AITAmount
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTCostCalculation AS TTCostCalculation
		|		ON TTCostCalculation.Ref = DocumentData.Ref
		|
		|WHERE
		|	(DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|		OR DocumentData.AccountingProcedureAC = VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses))
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Period                       AS Period,
		|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
		|	DocumentData.Organization                  AS Organization,
		|
		|   CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping
		|			THEN DocumentData.FixedAssetsLocation
		|		ELSE DocumentData.DepartmentACC
		|	END AS Department,
		|
		|	DocumentData.ExpenseItemAccounting             AS ExpenseItem,
		|	DocumentData.ExpensesDimensionAccounting          AS DimensionOfExpenses,
		|
		|	CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping
		|			THEN DocumentData.LineOfBusiness
		|		ELSE DocumentData.LineOfBusinessBookkeeping
		|	END AS LineOfBusiness,
		|
		|	UNDEFINED                                 AS VATActivityType,
		|
		|	0 AS AmountIncludingVAT,
		|	0 AS AmountExcludingVAT,
		|	0 AS AmountExcludingVATMan,
		|
		|	TTCostCalculation.AmountAccounting AS AmountIncludingVATCompl,
		|	TTCostCalculation.AmountAccounting AS AmountExcludingVATCompl,
		|
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|
		|	&Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount AS BusinessOperation,
		|	UNDEFINED                                 AS ItemsLocationAttributes,
		|	                                                                             
		|	TTCostCalculation.IdOfACLine      AS FinRecordID,
		|	&SettingUpHo_WriteOffOfCostsForExpensesWithoutTakingThemIntoAccount AS BusinessTransactionSetting,
		|
		|	DocumentData.Ref                       AS Recorder,
		|	TTCostCalculation.VariancePeriod           AS VariancePeriod
		|
		|	,0 AS AITAmount
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTCostCalculation AS TTCostCalculation
		|		ON TTCostCalculation.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.AccountingProcedureAC IN (
		|		VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses),
		|		VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses))
		|";
		
		ListOfRequests.Add(QueryText);
		
	EndIf;
	
	QueryText = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
	
	ListOfMergeRequests.Add(QueryText);
	
EndProcedure

Procedure ValuesOfParametersForFAAcceptanceForAccounting(ValuesOfHoldingParameters) Export
	
	ValuesOfHoldingParameters.Insert(
		"Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount", 
		Enums.BusinessTransactions.WriteOffOfFixedAssetsCostSkippingRecognition);
	
	ValuesOfHoldingParameters.Insert(
		"SettingUpHo_WriteOffOfCostsForExpensesWithoutTakingThemIntoAccount", 
		Catalogs.BusinessTransactionsSettings.WriteOffOfFixedAssetsCostSkippingRecognition);
	
	ListOfPermittedCostAllocationOptions = New Array;
	ListOfPermittedCostAllocationOptions.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	ListOfPermittedCostAllocationOptions.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
	ListOfPermittedCostAllocationOptions.Add(Enums.CostAllocationOptions.ToDeferredExpenses);
	ListOfPermittedCostAllocationOptions.Add(Enums.CostAllocationOptions.DoNotAllocate);
	ValuesOfHoldingParameters.Insert("ListOfPermittedCostAllocationOptions", ListOfPermittedCostAllocationOptions);
	
	ValuesOfHoldingParameters.Insert("APArticle", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
	ValuesOfHoldingParameters.Insert("PackageNumber", 0);
	
	
EndProcedure

Procedure ValuesOfParametersOfIAAcceptanceForAccounting(ValuesOfHoldingParameters) Export
	
	ValuesOfHoldingParameters.Insert(
		"Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount", 
		Enums.BusinessTransactions.WriteOffToExpensesOnIntangibleAssetCostWithoutRecognition);
	
	ValuesOfHoldingParameters.Insert(
		"SettingUpHo_WriteOffOfCostsForExpensesWithoutTakingThemIntoAccount", 
		Catalogs.BusinessTransactionsSettings.WriteOffToExpensesOnIntangibleAssetCostWithoutRecognition);

	ListOfPermittedCostAllocationOptions = New Array;
	ListOfPermittedCostAllocationOptions.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	ListOfPermittedCostAllocationOptions.Add(Enums.CostAllocationOptions.ToDeferredExpenses);
	ListOfPermittedCostAllocationOptions.Add(Enums.CostAllocationOptions.DoNotAllocate);
	ValuesOfHoldingParameters.Insert("ListOfPermittedCostAllocationOptions", ListOfPermittedCostAllocationOptions);
	
	ValuesOfHoldingParameters.Insert("APArticle", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets);
	ValuesOfHoldingParameters.Insert("PackageNumber", 0);
	
	
EndProcedure

#EndRegion

// 
// Parameters:
//  RegisterRequests - Array of String - 
Procedure TextOfTrafficRequestIncomeExpensesOtherAssetsLiabilitiesAcceptanceForAccounting(RegisterRequests) Export
	
	#Region Recognition // - Cr 08
	QueryText =
	"SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.BusinessOperation        AS BusinessOperation,
	|	DocumentData.Organization                  AS Organization,
	|
	|	TTCostCalculation.Department              AS Department,
	|	TTCostCalculation.LineOfBusiness    AS LineOfBusiness,
	|	TTCostCalculation.ExpenseItem             AS AssetRef,
	|	UNDEFINED                                 AS DimensionOfRevenue,
	|	TTCostCalculation.DimensionOfExpenses          AS DimensionOfExpenses,
	|	UNDEFINED                                 AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                 AS FinancialAccountingGroup,
	|
	|	DocumentData.FixedAssetsLocation              AS DebitBusinessUnit,
	|	DocumentData.LineOfBusiness      AS CorLineOfBusiness,
	|	&APArticle                                    AS CorItem,
	|	UNDEFINED                                 AS CorIncomeDimension,
	|	UNDEFINED                                 AS CorExpenditureDimension,
	|	TTCostCalculation.AccountingObject                AS CorDimensionOfAssetsLiabilities,
	|	DocumentData.FinancialAccountingGroup       AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                  AS CorCompany,
	|
	|	CASE
	|		WHEN NOT DocumentData.RecordInManAccounting
	|				OR DocumentData.AccountingProcedureMA = VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|			THEN 0
	|		ELSE TTCostCalculation.Sum
	|	END AS Sum,
	|
	|	CASE
	|		WHEN NOT DocumentData.PostInAccounting
	|				OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|			THEN 0
	|		ELSE TTCostCalculation.AmountAccounting + TTCostCalculation.CFAmount
	|	END AS SumCompl,
	|
	|	CASE
	|		WHEN NOT DocumentData.RecordInManAccounting
	|				OR DocumentData.AccountingProcedureMA = VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|			THEN 0
	|		ELSE TTCostCalculation.AmountOfUU
	|	END AS SumMan
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = DocumentData.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting 
	|		OR DocumentData.PostInAccounting)
	|";
	RegisterRequests.Add(QueryText);
	#EndRegion
	
	#Region DoNotTakeIntoAccountIncludeInExpenses
	QueryText =
	"SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	&Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount AS BusinessOperation,
	|	DocumentData.Organization                  AS Organization,
	|
	|	TTCostCalculation.Department              AS Department,
	|	TTCostCalculation.LineOfBusiness    AS LineOfBusiness,
	|	TTCostCalculation.ExpenseItem             AS AssetRef,
	|	UNDEFINED                                 AS DimensionOfRevenue,
	|	TTCostCalculation.DimensionOfExpenses          AS DimensionOfExpenses,
	|	UNDEFINED                                 AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                 AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
	|			THEN DocumentData.FixedAssetsLocation
	|		ELSE DocumentData.BusinessUnitManagementAccounting
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
	|			THEN DocumentData.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessManagementAccounting
	|	END AS CorLineOfBusiness,
	|
	|	DocumentData.ExpenseItemManagementAccounting             AS CorItem,
	|	UNDEFINED                                 AS CorIncomeDimension,
	|	DocumentData.ExpensesDimensionManagementAccounting          AS CorExpenditureDimension,
	|	UNDEFINED                                 AS CorDimensionOfAssetsLiabilities,
	|	UNDEFINED                                 AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                  AS CorCompany,
	|
	|	TTCostCalculation.Sum                      AS Sum,
	|	0                                            AS SumCompl,
	|	TTCostCalculation.AmountOfUU                    AS SumMan
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.AccountingProcedureMA = VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|	AND TTCostCalculation.AmountOfUU <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	&Ho_WriteOffOfCostsForExpensesWithoutTakingIntoAccount AS BusinessOperation,
	|	DocumentData.Organization                  AS Organization,
	|
	|	TTCostCalculation.Department              AS Department,
	|	TTCostCalculation.LineOfBusiness    AS LineOfBusiness,
	|	TTCostCalculation.ExpenseItem             AS AssetRef,
	|	UNDEFINED                                 AS DimensionOfRevenue,
	|	TTCostCalculation.DimensionOfExpenses          AS DimensionOfExpenses,
	|	UNDEFINED                                 AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                 AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping
	|			THEN DocumentData.FixedAssetsLocation
	|		ELSE DocumentData.DepartmentACC
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping
	|			THEN DocumentData.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessBookkeeping
	|	END AS CorLineOfBusiness,
	|
	|	DocumentData.ExpenseItemAccounting             AS CorItem,
	|	UNDEFINED                                 AS CorIncomeDimension,
	|	DocumentData.ExpensesDimensionAccounting          AS CorExpenditureDimension,
	|	UNDEFINED                                 AS CorDimensionOfAssetsLiabilities,
	|	UNDEFINED                                 AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                  AS CorCompany,
	|
	|	0                                            AS Sum,
	|
	|	TTCostCalculation.AmountAccounting
	|		+ TTCostCalculation.CFAmount              AS SumCompl,
	|
	|	0                                            AS SumMan
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTCostCalculation AS TTCostCalculation
	|		ON TTCostCalculation.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|	AND TTCostCalculation.AmountAccounting <> 0
	|";
	RegisterRequests.Add(QueryText);
	#EndRegion
	
EndProcedure

#Region DepreciationCalculation

// 
// Parameters:
//  MonthField - String - Month field
// 
// Returns:
//  String - 
Function TextOfPeriodCoefficientField(MonthField) Export
	
	FieldText =
	"	CASE
	|		WHEN FixedAssetDepreciationSchedules.Ref IS NULL
	|			THEN 0
	|		WHEN FixedAssetDepreciationSchedules.ZoomRatio1 
	|			+ FixedAssetDepreciationSchedules.ZoomRatio2 
	|			+ FixedAssetDepreciationSchedules.ZoomRatio3 
	|			+ FixedAssetDepreciationSchedules.ZoomRatio4 
	|			+ FixedAssetDepreciationSchedules.ZoomRatio5 
	|			+ FixedAssetDepreciationSchedules.ZoomRatio6 
	|			+ FixedAssetDepreciationSchedules.ZoomRatio7 
	|			+ FixedAssetDepreciationSchedules.ZoomRatio8 
	|			+ FixedAssetDepreciationSchedules.ZoomRatio9 
	|			+ FixedAssetDepreciationSchedules.ZoomRatio10 
	|			+ FixedAssetDepreciationSchedules.ZoomRatio11 
	|			+ FixedAssetDepreciationSchedules.ZoomRatio12 <> 0
	|		THEN 
	|			CASE MONTH(&BegOfMonth)
	|				WHEN 1 THEN ISNULL(FixedAssetDepreciationSchedules.ZoomRatio1, 0)
	|				WHEN 2 THEN ISNULL(FixedAssetDepreciationSchedules.ZoomRatio2, 0) 
	|				WHEN 3 THEN ISNULL(FixedAssetDepreciationSchedules.ZoomRatio3, 0)
	|				WHEN 4 THEN ISNULL(FixedAssetDepreciationSchedules.ZoomRatio4, 0) 
	|				WHEN 5 THEN ISNULL(FixedAssetDepreciationSchedules.ZoomRatio5, 0)
	|				WHEN 6 THEN ISNULL(FixedAssetDepreciationSchedules.ZoomRatio6, 0)
	|				WHEN 7 THEN ISNULL(FixedAssetDepreciationSchedules.ZoomRatio7, 0)
	|				WHEN 8 THEN ISNULL(FixedAssetDepreciationSchedules.ZoomRatio8, 0)
	|				WHEN 9 THEN ISNULL(FixedAssetDepreciationSchedules.ZoomRatio9, 0)
	|				WHEN 10 THEN ISNULL(FixedAssetDepreciationSchedules.ZoomRatio10, 0)
	|				WHEN 11 THEN ISNULL(FixedAssetDepreciationSchedules.ZoomRatio11, 0)
	|				WHEN 12 THEN ISNULL(FixedAssetDepreciationSchedules.ZoomRatio12, 0)
	|			END / (FixedAssetDepreciationSchedules.ZoomRatio1 
	|						+ FixedAssetDepreciationSchedules.ZoomRatio2 
	|						+ FixedAssetDepreciationSchedules.ZoomRatio3 
	|						+ FixedAssetDepreciationSchedules.ZoomRatio4 
	|						+ FixedAssetDepreciationSchedules.ZoomRatio5 
	|						+ FixedAssetDepreciationSchedules.ZoomRatio6 
	|						+ FixedAssetDepreciationSchedules.ZoomRatio7 
	|						+ FixedAssetDepreciationSchedules.ZoomRatio8 
	|						+ FixedAssetDepreciationSchedules.ZoomRatio9 
	|						+ FixedAssetDepreciationSchedules.ZoomRatio10 
	|						+ FixedAssetDepreciationSchedules.ZoomRatio11 
	|						+ FixedAssetDepreciationSchedules.ZoomRatio12)
	|		ELSE 0
	|	END";
	
	FieldText = StrReplace(FieldText, "&BegOfMonth", MonthField);
	
	Return FieldText;
		
EndFunction

// 
// Parameters:
//  NameOfAmountField - String - 
// 
// Returns:
//  String - 
Function TextOfDepreciationAmountDistribution(NameOfAmountField) Export
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		NameOfAmountField,
		"ISNULL(WaysToReflectDepreciation.Base, 0)",
		"ISNULL(WaysToReflectDepreciation.BaseAccumulated, 0)",
		"ISNULL(WaysToReflectDepreciation.BaseAmount, 0)");
		
	Return AmountDistributionText;
	
EndFunction

#EndRegion

#Region Revaluation

Procedure QueryTextTableRevaluationCost(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers)
	
	RegisterName = ?(KindOfAccountingObjects = "FA", "FACost", "IACost");
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTTRevaluationTable(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTIsEmptyTableFA(QueryTexts);
	
	CurRequestTexts = New Array;
	
	#Region Revaluation_IncreaseInValue
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	RevaluationTable.AccountingObject               AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness   AS LineOfBusiness,
	|	&Leaseholder                                  AS Leaseholder,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	UNDEFINED                                AS DebitBusinessUnit,
	|	UNDEFINED                                AS CorLineOfBusiness,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	CASE 
	|		WHEN (RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa - RevaluationTable.CostRevaluationReserve) > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa 
	|					- RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN (RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC - RevaluationTable.CostRevaluationReserveLocal) > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC 
	|					- RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN (RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC - RevaluationTable.CostRevaluationReserveLocal) > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC 
	|					- RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN (RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa - RevaluationTable.CostRevaluationReserve) > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa 
	|					- RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS CostRevaluationReserve,
	|	
	|	CASE 
	|		WHEN (RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC - RevaluationTable.CostRevaluationReserveLocal) > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC 
	|					- RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS CostRevaluationReserveLocal,
	|
	|	0 AS CostGainMA,
	|	0 AS CostGainLocal,
	|
	|	RevaluationTable.FinRecordID  AS FinRecordID,
	|	&BO_CostIncrease                   AS BusinessOperation,
	|	&SettingUpHO_CostIncrease          AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = RevaluationTable.Ref
	|			AND FALocation.FixedAsset = RevaluationTable.AccountingObject
	|
	|WHERE
	|	((RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa 
	|			- RevaluationTable.CostRevaluationReserve) > 0
	|		OR (RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC 
	|				- RevaluationTable.CostRevaluationReserveLocal) > 0)
	|";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	#Region AdditionalAssessment_CostIncreaseDueToMarkdowns
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	RevaluationTable.AccountingObject               AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness   AS LineOfBusiness,
	|	&Leaseholder                                  AS Leaseholder,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	UNDEFINED                                AS DebitBusinessUnit,
	|	UNDEFINED                                AS CorLineOfBusiness,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa > 0 AND RevaluationTable.CostRevaluationReserve > 0
	|			THEN RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC > 0 AND RevaluationTable.CostRevaluationReserveLocal > 0
	|			THEN RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC > 0 AND RevaluationTable.CostRevaluationReserveLocal > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0
	|	END AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa > 0 AND RevaluationTable.CostRevaluationReserve > 0
	|			THEN RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS CostRevaluationReserve,
	|	
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC > 0 AND RevaluationTable.CostRevaluationReserveLocal > 0
	|			THEN RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0
	|	END AS CostRevaluationReserveLocal,
	|
	|	0 AS CostGainMA,
	|	0 AS CostGainLocal,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&BO_CostIncreaseDueToMarkdowns AS BusinessOperation,
	|	&SettingUpBT_CostIncreaseDueToMarkdowns AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = RevaluationTable.Ref
	|			AND FALocation.FixedAsset = RevaluationTable.AccountingObject
	|
	|WHERE
	|	RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa > 0 AND RevaluationTable.CostRevaluationReserve > 0
	|		OR RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC > 0 AND RevaluationTable.CostRevaluationReserveLocal > 0
	|";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	#Region Markdown_DecreaseInValue
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	RevaluationTable.AccountingObject               AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness   AS LineOfBusiness,
	|	&Leaseholder                                  AS Leaseholder,
	|	DocumentData.ExpenseItem              AS CorExpenseItem,
	|	DocumentData.DimensionOfExpenses           AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMaMarkdown > 0
	|			THEN RevaluationTable.AmountOfMaMarkdown - RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0
	|			THEN RevaluationTable.AmountOfACCostMarkdown - RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.AmountOfACCostMarkdown - RevaluationTable.CostRevaluationReserveLocal 
	|		ELSE 0 
	|	END AS CostTemporaryDifference,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfDiscountOnCostOfCF > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.AmountOfDiscountOnCostOfCF
	|		ELSE 0 
	|	END AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfDiscountOnCostOfCF > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.AmountOfDiscountOnCostOfCF
	|		ELSE 0 
	|	END AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMaMarkdown > 0
	|			THEN RevaluationTable.AmountOfMaMarkdown - RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS CostRevaluationReserve,
	|	
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0
	|			THEN RevaluationTable.AmountOfACCostMarkdown - RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS CostRevaluationReserveLocal,
	|
	|	0 AS CostGainMA,
	|	0 AS CostGainLocal,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&BO_CostReduction                  AS BusinessOperation,
	|	&SettingUpHO_CostReduction         AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = RevaluationTable.Ref
	|			AND FALocation.FixedAsset = RevaluationTable.AccountingObject
	|
	|WHERE
	|	RevaluationTable.AmountOfMaMarkdown > 0
	|		OR RevaluationTable.AmountOfACCostMarkdown > 0
	|		OR RevaluationTable.AmountOfDiscountOnCostOfCF > 0";
	CurRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region Markdown_CostReductionDueToReEvaluation 
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	RevaluationTable.AccountingObject               AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness   AS LineOfBusiness,
	|	&Leaseholder                                  AS Leaseholder,
	|	DocumentData.ExpenseItem              AS CorExpenseItem,
	|	DocumentData.DimensionOfExpenses           AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMaMarkdown > 0 
	|				AND RevaluationTable.CostRevaluationReserve > 0
	|			THEN RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0 
	|				AND RevaluationTable.CostRevaluationReserveLocal > 0
	|			THEN RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0 
	|				AND RevaluationTable.CostRevaluationReserveLocal > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0
	|	END AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0 AND RevaluationTable.CostRevaluationReserve > 0
	|			THEN RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS CostRevaluationReserve,
	|	
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0 AND RevaluationTable.CostRevaluationReserveLocal > 0
	|			THEN RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0
	|	END AS CostRevaluationReserveLocal,
	|
	|	0 AS CostGainMA,
	|	0 AS CostGainLocal,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&HO_CostReductionDueToAdditionalAssessment AS BusinessOperation,
	|	&SettingUpBT_CostReductionDueToAdditionalAssessment AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = RevaluationTable.Ref
	|			AND FALocation.FixedAsset = RevaluationTable.AccountingObject
	|
	|WHERE
	|	RevaluationTable.AmountOfMaMarkdown > 0 AND RevaluationTable.CostRevaluationReserve > 0
	|		OR RevaluationTable.AmountOfACCostMarkdown > 0 AND RevaluationTable.CostRevaluationReserveLocal > 0
	|";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	#Region Markdown_ReductionOfDepreciationBalanceMethod
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	RevaluationTable.AccountingObject               AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness   AS LineOfBusiness,
	|	&Leaseholder                                  AS Leaseholder,
	|	DocumentData.ExpenseItem              AS CorExpenseItem,
	|	DocumentData.DimensionOfExpenses           AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	CASE 
	|		WHEN RevaluationTable.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND RevaluationTable.AmountOfMarkdownDepreciationMa > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationMa
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN RevaluationTable.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND RevaluationTable.AmountOfMarkdownDepreciationAC > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationAC
	|		ELSE 0 
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN RevaluationTable.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND RevaluationTable.AmountOfMarkdownDepreciationAC > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationAC 
	|		ELSE 0 
	|	END AS CostTemporaryDifference,
	|
	|	CASE 
	|		WHEN RevaluationTable.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND RevaluationTable.AmountOfMarkdownDepreciationCF > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationCF
	|		ELSE 0 
	|	END AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN RevaluationTable.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND RevaluationTable.AmountOfMarkdownDepreciationCF > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationCF
	|		ELSE 0 
	|	END AS CostTargetFinancingPD,
	|
	|	0 AS CostRevaluationReserve,
	|	0 AS CostRevaluationReserveLocal,
	|
	|	0 AS CostGainMA,
	|	0 AS CostGainLocal,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&BO_DepreciationReductionNetMethod AS BusinessOperation,
	|	&SettingUpBT_DepreciationReductionBalanceMethod AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = RevaluationTable.Ref
	|			AND FALocation.FixedAsset = RevaluationTable.AccountingObject
	|
	|WHERE
	|	(RevaluationTable.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|			AND RevaluationTable.AmountOfMarkdownDepreciationMa > 0
	|		OR RevaluationTable.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|			AND (RevaluationTable.AmountOfMarkdownDepreciationAC > 0
	|				OR RevaluationTable.AmountOfMarkdownDepreciationCF > 0))";
	CurRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region CostIncrease_CostIncrease
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	RevaluationTable.AccountingObject               AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness   AS LineOfBusiness,
	|	UNDEFINED                                AS Leaseholder,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	UNDEFINED                                AS DebitBusinessUnit,
	|	UNDEFINED                                AS CorLineOfBusiness,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostTemporaryDifference,
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|	0 AS CostRevaluationReserve,
	|	0 AS CostRevaluationReserveLocal,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa - RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS CostGainMA,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC - RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS CostGainLocal,
	|
	|	RevaluationTable.FinRecordID  AS FinRecordID,
	|	&BO_CostIncrease                   AS BusinessOperation,
	|	&SettingUpHO_CostIncrease          AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	(RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa > 0
	|		OR RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC > 0)";
	CurRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region CostIncrease_DepreciationIncrease
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	RevaluationTable.AccountingObject               AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness   AS LineOfBusiness,
	|	UNDEFINED                                AS Leaseholder,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	UNDEFINED                                AS DebitBusinessUnit,
	|	UNDEFINED                                AS CorLineOfBusiness,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostTemporaryDifference,
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|	0 AS CostRevaluationReserve,
	|	0 AS CostRevaluationReserveLocal,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation - RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS CostGainMA,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation - RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0 
	|	END AS CostGainLocal,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&BO_IncreasedDepreciation AS BusinessOperation,
	|	&SettingHO_IncreaseDepreciation AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	(RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation - RevaluationTable.DepreciationRevaluationReserve) > 0
	|		OR (RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation - RevaluationTable.DepreciationRevaluationReserveLocal) > 0
	|			AND NOT RevaluationTable.AccrueDepreciation";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	#Region CostIncrease_CostDecreaseDueToAdditionalValuation 
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	RevaluationTable.AccountingObject               AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness   AS LineOfBusiness,
	|	UNDEFINED                                AS Leaseholder,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	UNDEFINED                                AS DebitBusinessUnit,
	|	UNDEFINED                                AS CorLineOfBusiness,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostTemporaryDifference,
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|	0 AS CostRevaluationReserve,
	|	0 AS CostRevaluationReserveLocal,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0 AND RevaluationTable.CostRevaluationReserve > 0
	|			THEN RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS CostGainMA,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0 AND RevaluationTable.CostRevaluationReserveLocal > 0
	|			THEN RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0
	|	END AS CostGainLocal,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&HO_CostReductionDueToAdditionalAssessment AS BusinessOperation,
	|	&SettingUpBT_CostReductionDueToAdditionalAssessment AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	RevaluationTable.AmountOfMaMarkdown > 0 AND RevaluationTable.CostRevaluationReserve > 0
	|		OR RevaluationTable.AmountOfACCostMarkdown > 0 AND RevaluationTable.CostRevaluationReserveLocal > 0";
	CurRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region CostIncrease_DecreaseInDepreciationDueToRevaluation 
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	RevaluationTable.AccountingObject               AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness   AS LineOfBusiness,
	|	UNDEFINED                                AS Leaseholder,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	UNDEFINED                                AS DebitBusinessUnit,
	|	UNDEFINED                                AS CorLineOfBusiness,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostTemporaryDifference,
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|	0 AS CostRevaluationReserve,
	|	0 AS CostRevaluationReserveLocal,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationMa > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS CostGainMA,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationAC > 0 AND RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS CostGainLocal,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&HO_ReductionOfDepreciationDueToAdditionalValuation AS BusinessOperation,
	|	&SettingUpBT_ReductionOfDepreciationDueToAdditionalAssessment AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	RevaluationTable.AmountOfMarkdownDepreciationMa > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|		OR RevaluationTable.AmountOfMarkdownDepreciationAC > 0 AND RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			AND NOT RevaluationTable.AccrueDepreciation";
	CurRequestTexts.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(CurRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReplaceQueryTextParametersWhenReevaluating(QueryText, KindOfAccountingObjects, DocumentName);
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableDepreciationOnRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers)

	RegisterName = ?(KindOfAccountingObjects = "FA", "FixedAssetsDepreciationCharge", "IntangibleAssetsAmortizationCharge");
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTTRevaluationTable(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	
	CurRequestTexts = New Array;
	
	#Region AdditionalAssessment_IncreaseInDepreciation
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	RevaluationTable.AccountingObject          AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                           AS CorExpenseItem,
	|	UNDEFINED                           AS CorExpenditureDimension,
	|	UNDEFINED                           AS DebitBusinessUnit,
	|	UNDEFINED                           AS CorLineOfBusiness,
	|	RevaluationTable.AccrueDepreciation       AS AccrueDepreciation,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation - RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation - RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0 
	|	END AS DepreciationLocal,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation - RevaluationTable.DepreciationRevaluationReserveLocal 
	|		ELSE 0 
	|	END AS DepreciationTD,
	|
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationTargetFinancingPD,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation - RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS DepreciationRevaluationReserve,
	|	
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation - RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0 
	|	END AS DepreciationRevaluationReserveLocal,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&BO_IncreasedDepreciation AS BusinessOperation,
	|	&SettingHO_IncreaseDepreciation AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON RevaluationTable.Ref = DocumentData.Ref 
	|
	|WHERE
	|	(RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation - RevaluationTable.DepreciationRevaluationReserve) > 0
	|		OR (RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation - RevaluationTable.DepreciationRevaluationReserveLocal) > 0";
	CurRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region AdditionalValuation_IncreaseInDepreciationDueToMarkdowns
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	RevaluationTable.AccountingObject          AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ExpenseItem         AS CorExpenseItem,
	|	DocumentData.DimensionOfExpenses      AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	RevaluationTable.AccrueDepreciation       AS AccrueDepreciation,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS DepreciationTD,
	|
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationTargetFinancingPD,
	|
	|	CASE 
	|		WHEN RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS DepreciationRevaluationReserve,
	|	
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS DepreciationRevaluationReserveLocal,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&BO_IncreaseInDepreciationDueToMarkdowns AS BusinessOperation,
	|	&SettingUpBT_IncreaseDepreciationDueToMarkdowns AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON RevaluationTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	(RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|		OR RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation > 0 AND RevaluationTable.DepreciationRevaluationReserveLocal > 0)";
	CurRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region Markdown_ReductionOfDepreciation
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	RevaluationTable.AccountingObject          AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                           AS CorExpenseItem,
	|	UNDEFINED                           AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.IncomeBusinessUnit
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessIncome
	|	END AS CorLineOfBusiness,
	|
	|	RevaluationTable.AccrueDepreciation       AS AccrueDepreciation,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationMa > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationMa - RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationAC > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationAC - RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0 
	|	END AS DepreciationLocal,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationAC > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationAC - RevaluationTable.DepreciationRevaluationReserveLocal 
	|		ELSE 0 
	|	END AS DepreciationTD,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationCF > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationCF
	|		ELSE 0 
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationCF > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationCF
	|		ELSE 0 
	|	END AS DepreciationTargetFinancingPD,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationMa > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationMa - RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS DepreciationRevaluationReserve,
	|	
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationAC > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationAC - RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0 
	|	END AS DepreciationRevaluationReserveLocal,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&BO_DecreaseInDepreciation AS BusinessOperation,
	|	&SettingHO_ReductionOfDepreciation AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON RevaluationTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	(RevaluationTable.AmountOfMarkdownDepreciationMa - RevaluationTable.DepreciationRevaluationReserve) > 0
	|				AND RevaluationTable.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|		OR (RevaluationTable.AmountOfMarkdownDepreciationAC - RevaluationTable.DepreciationRevaluationReserveLocal) > 0
	|				AND RevaluationTable.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND NOT RevaluationTable.AccrueDepreciation
	|		OR RevaluationTable.AmountOfMarkdownDepreciationCF > 0
	|				AND RevaluationTable.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND NOT RevaluationTable.AccrueDepreciation
	|";
	CurRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region Markdown_ReductionOfDepreciationDueToAdditionalValuation 
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	RevaluationTable.AccountingObject          AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                           AS CorExpenseItem,
	|	UNDEFINED                           AS CorExpenditureDimension,
	|	UNDEFINED                           AS DebitBusinessUnit,
	|	UNDEFINED                           AS CorLineOfBusiness,
	|
	|	RevaluationTable.AccrueDepreciation       AS AccrueDepreciation,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationMa > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationAC > 0 AND RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationAC > 0 AND RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|				AND &ComplianceCAAccountingIsKept
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS DepreciationTD,
	|
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationTargetFinancingPD,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationMa > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS DepreciationRevaluationReserve,
	|	
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationAC > 0 AND RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS DepreciationRevaluationReserveLocal,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&HO_ReductionOfDepreciationDueToAdditionalValuation AS BusinessOperation,
	|	&SettingUpBT_ReductionOfDepreciationDueToAdditionalAssessment AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON RevaluationTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	(RevaluationTable.AmountOfMarkdownDepreciationMa > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|				AND RevaluationTable.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|		OR RevaluationTable.AmountOfMarkdownDepreciationAC > 0 AND RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|				AND RevaluationTable.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod))
	|";
	CurRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region DepreciationReductionNetMethod
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Ref                 AS Recorder,
	|	DocumentData.Period                 AS Period,
	|	DocumentData.Organization            AS Organization,
	|	DocumentData.Department          AS Department,
	|	RevaluationTable.AccountingObject          AS FixedAsset,
	|	RevaluationTable.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ExpenseItem         AS CorExpenseItem,
	|	DocumentData.DimensionOfExpenses      AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.IncomeBusinessUnit
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessIncome
	|	END AS CorLineOfBusiness,
	|
	|	RevaluationTable.AccrueDepreciation       AS AccrueDepreciation,
	|
	|	CASE 
	|		WHEN RevaluationTable.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND RevaluationTable.AmountOfMarkdownDepreciationMa > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationMa
	|		ELSE 0
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN RevaluationTable.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND RevaluationTable.AmountOfMarkdownDepreciationAC > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationAC
	|		ELSE 0 
	|	END AS DepreciationLocal,
	|
	|	CASE 
	|		WHEN RevaluationTable.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND RevaluationTable.AmountOfMarkdownDepreciationAC > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationAC 
	|		ELSE 0 
	|	END AS DepreciationTD,
	|
	|	CASE 
	|		WHEN RevaluationTable.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND RevaluationTable.AmountOfMarkdownDepreciationCF > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationCF
	|		ELSE 0 
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	|	CASE 
	|		WHEN RevaluationTable.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND RevaluationTable.AmountOfMarkdownDepreciationCF > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationCF
	|		ELSE 0 
	|	END AS DepreciationTargetFinancingPD,
	|
	|	0 AS DepreciationRevaluationReserve,
	|	0 AS DepreciationRevaluationReserveLocal,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&BO_DepreciationReductionNetMethod AS BusinessOperation,
	|	&SettingUpBT_DepreciationReductionBalanceMethod AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON RevaluationTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	(RevaluationTable.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|			AND RevaluationTable.AmountOfMarkdownDepreciationMa > 0
	|		OR RevaluationTable.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|			AND (RevaluationTable.AmountOfMarkdownDepreciationAC > 0
	|				OR RevaluationTable.AmountOfMarkdownDepreciationCF > 0))";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(CurRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReplaceQueryTextParametersWhenReevaluating(QueryText, KindOfAccountingObjects, DocumentName);
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableOtherRevaluationGains(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers)

	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryTextTTRevaluationTable(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTReflectionOfIncomeExpensesImpairment(QueryTexts);
	
	CurRequestTexts = New Array;
	
	#Region CostIncreaseDueToMarkdowns
	QueryText =
	"SELECT
	|	DocumentData.Ref                         AS Recorder,
	|	DocumentData.Period                         AS Period,
	|	DocumentData.Organization                    AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.IncomeBusinessUnit
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessIncome
	|	END AS LineOfBusiness,
	|
	|	DocumentData.IncomeItem                  AS IncomeItem,
	|	DocumentData.DimensionOfRevenue               AS DimensionOfRevenue,
	|
	|	CASE 
	|		WHEN RevaluationTable.CostRevaluationReserve > 0
	|			THEN RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS Sum,
	|	
	|	CASE 
	|		WHEN NOT ISNULL(BatchAccountingParameters.CompanyManagementAccounting, FALSE)
	|			THEN 0
	|		WHEN RevaluationTable.CostRevaluationReserve > 0
	|			THEN RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS SumMan,
	|	
	|	CASE 
	|		WHEN NOT ISNULL(BatchAccountingParameters.UseAccountingOfOtherIncomeExpensesInLocalAccounting, FALSE)
	|			THEN 0
	|		WHEN RevaluationTable.CostRevaluationReserveLocal > 0
	|			THEN RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0
	|	END AS SumCompl,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&BO_CostIncreaseDueToMarkdowns AS BusinessOperation,
	|	&SettingUpBT_CostIncreaseDueToMarkdowns AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON RevaluationTable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTParametersOfBatchAccountingForConducting AS BatchAccountingParameters
	|		ON BatchAccountingParameters.Period = BEGINOFPERIOD(DocumentData.Period, MONTH)
	|			AND BatchAccountingParameters.Organization = DocumentData.Organization
	|
	|WHERE
	|	RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa > 0 AND RevaluationTable.CostRevaluationReserve > 0
	|		OR RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC > 0 AND RevaluationTable.CostRevaluationReserveLocal > 0";
	CurRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region DecreaseInDepreciation
	QueryText =
	"SELECT
	|	DocumentData.Ref                         AS Recorder,
	|	DocumentData.Period                         AS Period,
	|	DocumentData.Organization                    AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.IncomeBusinessUnit
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessIncome
	|	END AS LineOfBusiness,
	|
	|	DocumentData.IncomeItem                  AS IncomeItem,
	|	DocumentData.DimensionOfRevenue               AS DimensionOfRevenue,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationMa > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationMa - RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN NOT ISNULL(BatchAccountingParameters.CompanyManagementAccounting, FALSE)
	|			THEN 0
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationMa > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationMa - RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN NOT ISNULL(BatchAccountingParameters.UseAccountingOfOtherIncomeExpensesInLocalAccounting, FALSE)
	|			THEN 0
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN (RevaluationTable.AmountOfMarkdownDepreciationAC + RevaluationTable.AmountOfMarkdownDepreciationCF) > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationAC 
	|					+ RevaluationTable.AmountOfMarkdownDepreciationCF
	|					- RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0 
	|	END AS SumCompl,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&BO_DecreaseInDepreciation AS BusinessOperation,
	|	&SettingHO_ReductionOfDepreciation AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON RevaluationTable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTParametersOfBatchAccountingForConducting AS BatchAccountingParameters
	|		ON BatchAccountingParameters.Period = BEGINOFPERIOD(DocumentData.Period, MONTH)
	|			AND BatchAccountingParameters.Organization = DocumentData.Organization
	|
	|WHERE
	|	(RevaluationTable.AmountOfMarkdownDepreciationMa - RevaluationTable.DepreciationRevaluationReserve) > 0
	|				AND RevaluationTable.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|		OR (RevaluationTable.AmountOfMarkdownDepreciationAC - RevaluationTable.DepreciationRevaluationReserveLocal) > 0
	|				AND RevaluationTable.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|				AND NOT RevaluationTable.AccrueDepreciation
	|";
	CurRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region RecoverImpairmentLoss
	QueryText =
	"SELECT
	|	DocumentData.Ref                         AS Recorder,
	|	DocumentData.Period                         AS Period,
	|	DocumentData.Organization                    AS Organization,
	|	DocumentData.Department                  AS Department,
	|	RevaluationTable.LineOfBusiness      AS LineOfBusiness,
	|
	|	TTReflectionOfIncomeExpenses.IncomeItem       AS IncomeItem,
	|	TTReflectionOfIncomeExpenses.DimensionOfRevenue    AS DimensionOfRevenue,
	|
	|	CASE 
	|		WHEN RevaluationTable.ReserveForRevaluationOfImpairmentMan > 0
	|			THEN RevaluationTable.ReserveForRevaluationOfImpairmentMan
	|		ELSE 0
	|	END AS Sum,
	|	
	|	CASE 
	|		WHEN NOT ISNULL(BatchAccountingParameters.CompanyManagementAccounting, FALSE)
	|			THEN 0
	|		WHEN RevaluationTable.ReserveForRevaluationOfImpairmentMan > 0
	|			THEN RevaluationTable.ReserveForRevaluationOfImpairmentMan
	|		ELSE 0
	|	END AS SumMan,
	|	
	|	CASE 
	|		WHEN NOT ISNULL(BatchAccountingParameters.UseAccountingOfOtherIncomeExpensesInLocalAccounting, FALSE)
	|			THEN 0
	|		WHEN RevaluationTable.ImpairmentRevaluationReserveLocal > 0
	|			THEN RevaluationTable.ImpairmentRevaluationReserveLocal
	|		ELSE 0
	|	END AS SumCompl,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&BO_RecoverImpairmentLoss AS BusinessOperation,
	|	&SettingUpBT_RecoveryOfImpairmentLoss AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|		INNER JOIN TTReflectionOfIncomeExpensesImpairment AS TTReflectionOfIncomeExpenses
	|		ON TTReflectionOfIncomeExpenses.Ref = RevaluationTable.Ref
	|			AND TTReflectionOfIncomeExpenses.AccountingObject = RevaluationTable.AccountingObject
	|
	|		INNER JOIN TTParametersOfBatchAccountingForConducting AS BatchAccountingParameters
	|		ON BatchAccountingParameters.Period = BEGINOFPERIOD(DocumentData.Period, MONTH)
	|			AND BatchAccountingParameters.Organization = DocumentData.Organization
	|
	|WHERE
	|	(RevaluationTable.ReserveForRevaluationOfImpairmentMan <> 0
	|		OR RevaluationTable.ImpairmentRevaluationReserveLocal <> 0)
	|";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	NonCurrentAssetsLocalization.AddQueryTextToTableOtherIncomeAtRevaluation(CurRequestTexts);
	
	QueryText = StrConcat(CurRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction
 
Function QueryTextTableOtherRevaluationCosts(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers) 
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	Add_Fields = "Recorder";

	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherCostsAtRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherCostsAtRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Add_Fields)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherCostsAtRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherCostsAtRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Add_Fields)
	
	RegisterName = "TTInitialOtherExpenses";

	QueryTextTTRevaluationTable(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	
	ListOfRequests = New Array;
	ListOfRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));

	#Region CostReduction
	QueryText = 
	"SELECT
	|	DocumentData.Period                      AS Period,
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Organization                 AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS Department,
	|
	|	DocumentData.ExpenseItem              AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses           AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                AS VATActivityType,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMaMarkdown > 0
	|			THEN RevaluationTable.AmountOfMaMarkdown - RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS AmountIncludingVAT,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMaMarkdown > 0
	|			THEN RevaluationTable.AmountOfMaMarkdown - RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS AmountExcludingVAT,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMaMarkdown > 0
	|			THEN RevaluationTable.AmountOfMaMarkdown - RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS AmountExcludingVATMan,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0
	|			THEN RevaluationTable.AmountOfACCostMarkdown - RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS AmountIncludingVATCompl,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0
	|			THEN RevaluationTable.AmountOfACCostMarkdown - RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS AmountExcludingVATCompl,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0
	|			THEN RevaluationTable.AmountOfACCostMarkdown - RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS PermanentDifference,
	|
	|	0 AS CostTD,
	|
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&SettingUpHO_CostReduction AS BusinessTransactionSetting
	|
	|	,DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS OtherItemsOfExpenditure
	|		ON DocumentData.ExpenseItem = OtherItemsOfExpenditure.Ref
	|
	|WHERE
	|	(RevaluationTable.AmountOfMaMarkdown > 0
	|		OR RevaluationTable.AmountOfACCostMarkdown > 0)
	|	AND NOT OtherItemsOfExpenditure.CostAllocationOptionLocal IN (
	|		VALUE(Enum.CostAllocationOptions.OnOtherAssets),
	|		VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region IncreaseInDepreciationDueToMarkdowns
	QueryText =
	"SELECT
	|	DocumentData.Period                      AS Period,
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Organization                 AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS Department,
	|
	|	DocumentData.ExpenseItem              AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses           AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                AS VATActivityType,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0 
	|				AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS AmountIncludingVAT,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0 
	|				AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS AmountExcludingVAT,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0 
	|				AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS AmountExcludingVATMan,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS AmountIncludingVATCompl,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS AmountExcludingVATCompl,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS PermanentDifference,
	|
	|	0 AS CostTD,
	|
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&SettingUpBT_IncreaseDepreciationDueToMarkdowns AS BusinessTransactionSetting
	|
	|	,DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS OtherItemsOfExpenditure
	|		ON DocumentData.ExpenseItem = OtherItemsOfExpenditure.Ref
	|
	|WHERE
	|	(RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|		OR NOT RevaluationTable.AccrueDepreciation 
	|				AND RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation > 0 
	|				AND RevaluationTable.DepreciationRevaluationReserveLocal > 0)
	|	AND NOT OtherItemsOfExpenditure.CostAllocationOptionLocal IN (
	|		VALUE(Enum.CostAllocationOptions.OnOtherAssets),
	|		VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTableOfOtherExpensesAtRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers) 
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	Add_Fields = "Recorder";

	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableOfTTAndOtherExpensesAtRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots(Add_Fields);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOfTTAndOtherExpensesAtRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Add_Fields)
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpensesAtRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpensesAtRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Add_Fields)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	QueryTextTTRevaluationTable(Query, QueryTexts, KindOfAccountingObjects, DocumentName);

	ListOfRequests = New Array;
	ListOfRequests.Add(AccumulationRegisters.ItemisedExpensesLots.TextDescriptionTTInitialBatchesOfOtherExpenses(Add_Fields));

	#Region CostReduction
	
	QueryText = 
	"SELECT
	|	DocumentData.Period                      AS Period,
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Organization                 AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS Department,
	|
	|	DocumentData.ExpenseItem              AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses           AS DimensionOfExpenses,
	|	UNDEFINED                                AS AssetsLiabilitiesDimension,
	|	DocumentData.Ref                      AS ExpenseReceiptDocument,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                AS ItemsLocationAttributes,
	|	UNDEFINED                                AS VATActivityType,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMaMarkdown > 0
	|			THEN RevaluationTable.AmountOfMaMarkdown - RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMaMarkdown > 0
	|			THEN RevaluationTable.AmountOfMaMarkdown - RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS CostExcludingVAT,
	|
	|	0 AS VATManag,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0
	|			THEN RevaluationTable.AmountOfACCostMarkdown - RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS LocalCost,
	|
	|	0 AS VATLocal,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0
	|			THEN RevaluationTable.AmountOfACCostMarkdown - RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS PermanentDifference,
	|
	|	0 AS CostTD,
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&SettingUpHO_CostReduction AS BusinessTransactionSetting
	|
	|	,DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS OtherItemsOfExpenditure
	|		ON DocumentData.ExpenseItem = OtherItemsOfExpenditure.Ref
	|
	|WHERE
	|	(RevaluationTable.AmountOfMaMarkdown > 0
	|		OR RevaluationTable.AmountOfACCostMarkdown > 0)
	|	AND OtherItemsOfExpenditure.CostAllocationOptionLocal IN (
	|		VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region IncreaseInDepreciationDueToMarkdowns
	QueryText =
	"SELECT
	|	DocumentData.Period                      AS Period,
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Organization                 AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS Department,
	|
	|	DocumentData.ExpenseItem              AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses           AS DimensionOfExpenses,
	|	UNDEFINED                                AS AssetsLiabilitiesDimension,
	|	DocumentData.Ref                      AS ExpenseReceiptDocument,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	UNDEFINED                                AS ItemsLocationAttributes,
	|	UNDEFINED                                AS VATActivityType,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0 
	|				AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0 
	|				AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS CostExcludingVAT,
	|
	|	0 AS VATManag,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	0 AS VATLocal,
	|
	|	CASE 
	|		WHEN RevaluationTable.AccrueDepreciation
	|			THEN 0
	|		WHEN RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS PermanentDifference,
	|
	|	0 AS CostTD,
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
	|
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&SettingUpBT_IncreaseDepreciationDueToMarkdowns AS BusinessTransactionSetting
	|
	|	,DocumentData.Ref AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS OtherItemsOfExpenditure
	|		ON DocumentData.ExpenseItem = OtherItemsOfExpenditure.Ref
	|
	|WHERE
	|	(RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|		OR NOT RevaluationTable.AccrueDepreciation 
	|				AND RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation > 0 
	|				AND RevaluationTable.DepreciationRevaluationReserveLocal > 0)
	|	AND OtherItemsOfExpenditure.CostAllocationOptionLocal IN (
	|		VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableOfRegisteredRecordsIncomeExpensesOtherAssetsLiabilitiesAtRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTTRevaluationTable(Query, QueryTexts, KindOfAccountingObjects, DocumentName);

	CurRequestTexts = New Array;

	#Region Revaluation_IncreaseInValue
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_CostIncrease                    AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|	DocumentData.Department              AS Department,
	|	RevaluationTable.LineOfBusiness  AS LineOfBusiness,
	|
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	RevaluationTable.AccountingObject              AS AssetsLiabilitiesDimension,
	|	RevaluationTable.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	RevaluationTable.LineOfBusiness  AS CorLineOfBusiness,
	|	&ArticleAP_AccountingObject                      AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	RevaluationTable.AccountingObject              AS CorDimensionOfAssetsLiabilities,
	|	RevaluationTable.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                AS CorCompany,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa - RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa - RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC - RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	(RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa > 0
	|		OR RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC > 0)";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	#Region AdditionalAssessment_CostIncreaseDueToMarkdowns
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_CostIncreaseDueToMarkdowns        AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.IncomeBusinessUnit
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessIncome
	|	END AS LineOfBusiness,
	|
	|	DocumentData.IncomeItem              AS AssetRef,
	|	DocumentData.DimensionOfRevenue           AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	UNDEFINED                               AS AssetsLiabilitiesDimension,
	|	RevaluationTable.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	RevaluationTable.LineOfBusiness  AS CorLineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	RevaluationTable.AccountingObject              AS CorDimensionOfAssetsLiabilities,
	|	RevaluationTable.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                AS CorCompany,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa > 0 
	|				AND RevaluationTable.CostRevaluationReserve > 0
	|			THEN RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa > 0 
	|				AND RevaluationTable.CostRevaluationReserve > 0
	|			THEN RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN RevaluationTable.CostRevaluationReserveLocal > 0
	|			THEN RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	RevaluationTable.AmountOfAdditionalAssessmentOfCostOfMa > 0 
	|			AND RevaluationTable.CostRevaluationReserve > 0
	|		OR RevaluationTable.AmountOfAdditionalAssessmentOfCostOfAC > 0 
	|			AND RevaluationTable.CostRevaluationReserveLocal > 0
	|";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	#Region AdditionalAssessment_IncreaseInDepreciation
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_IncreasedDepreciation                  AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	DocumentData.Department              AS Department,
	|	RevaluationTable.LineOfBusiness  AS LineOfBusiness,
	|	&ArticleAP_AccountingObject                      AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	RevaluationTable.AccountingObject              AS AssetsLiabilitiesDimension,
	|	RevaluationTable.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	RevaluationTable.LineOfBusiness  AS CorLineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	RevaluationTable.AccountingObject              AS CorDimensionOfAssetsLiabilities,
	|	RevaluationTable.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                AS CorCompany,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation - RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation - RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation > 0
	|			THEN RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation - RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0 
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	(RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation - RevaluationTable.DepreciationRevaluationReserve) > 0
	|		OR (RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation - RevaluationTable.DepreciationRevaluationReserveLocal) > 0";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	#Region AdditionalValuation_IncreaseInDepreciationDueToMarkdowns
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_IncreaseInDepreciationDueToMarkdowns      AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	DocumentData.Department              AS Department,
	|	RevaluationTable.LineOfBusiness  AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	RevaluationTable.AccountingObject              AS AssetsLiabilitiesDimension,
	|	RevaluationTable.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	RevaluationTable.LineOfBusiness  AS CorLineOfBusiness,
	|	DocumentData.ExpenseItem             AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	DocumentData.DimensionOfExpenses          AS CorExpenditureDimension,
	|	UNDEFINED                               AS CorDimensionOfAssetsLiabilities,
	|	RevaluationTable.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                AS CorCompany,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	RevaluationTable.AmountOfAdditionalAssessmentOfMaDepreciation > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|		OR RevaluationTable.AmountOfAdditionalAssessmentOfACDepreciation > 0 AND RevaluationTable.DepreciationRevaluationReserveLocal > 0";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	#Region Markdown_DecreaseInValue
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_CostReduction                    AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	DocumentData.Department              AS Department,
	|	RevaluationTable.LineOfBusiness  AS LineOfBusiness,
	|	&ArticleAP_AccountingObject                      AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	RevaluationTable.AccountingObject              AS AssetsLiabilitiesDimension,
	|	RevaluationTable.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.ExpensesBusinessUnit
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.ExpenseLineOfBusiness
	|	END  AS CorLineOfBusiness,
	|
	|	DocumentData.ExpenseItem             AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	DocumentData.DimensionOfExpenses          AS CorExpenditureDimension,
	|	UNDEFINED                               AS CorDimensionOfAssetsLiabilities,
	|	UNDEFINED                               AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                AS CorCompany,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMaMarkdown > 0
	|			THEN RevaluationTable.AmountOfMaMarkdown - RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMaMarkdown > 0
	|			THEN RevaluationTable.AmountOfMaMarkdown - RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0
	|			THEN RevaluationTable.AmountOfACCostMarkdown - RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	RevaluationTable.AmountOfMaMarkdown > 0
	|		OR RevaluationTable.AmountOfACCostMarkdown > 0";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	#Region Markdown_CostReductionDueToReEvaluation 
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&HO_CostReductionDueToAdditionalAssessment      AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	DocumentData.Department              AS Department,
	|	RevaluationTable.LineOfBusiness  AS LineOfBusiness,
	|	&ArticleAP_AccountingObject                      AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	RevaluationTable.AccountingObject              AS AssetsLiabilitiesDimension,
	|	RevaluationTable.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	RevaluationTable.LineOfBusiness  AS CorLineOfBusiness,
	|	&ArticleAP_AccountingObject                      AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	RevaluationTable.AccountingObject              AS CorDimensionOfAssetsLiabilities,
	|	RevaluationTable.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                AS CorCompany,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMaMarkdown > 0 AND RevaluationTable.CostRevaluationReserve > 0
	|			THEN RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMaMarkdown > 0 AND RevaluationTable.CostRevaluationReserve > 0
	|			THEN RevaluationTable.CostRevaluationReserve
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfACCostMarkdown > 0 AND RevaluationTable.CostRevaluationReserveLocal > 0
	|			THEN RevaluationTable.CostRevaluationReserveLocal
	|		ELSE 0
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	RevaluationTable.AmountOfMaMarkdown > 0 AND RevaluationTable.CostRevaluationReserve > 0
	|		OR RevaluationTable.AmountOfACCostMarkdown > 0 AND RevaluationTable.CostRevaluationReserveLocal > 0";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	#Region Markdown_ReductionOfDepreciation
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&BO_DecreaseInDepreciation                  AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	CASE
	|		WHEN DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DocumentData.Department
	|		ELSE DocumentData.IncomeBusinessUnit
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.IncomeBusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN RevaluationTable.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessIncome
	|	END AS LineOfBusiness,
	|
	|	DocumentData.IncomeItem              AS AssetRef,
	|	DocumentData.DimensionOfRevenue           AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	UNDEFINED                               AS AssetsLiabilitiesDimension,
	|	UNDEFINED                               AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	RevaluationTable.LineOfBusiness  AS CorLineOfBusiness,
	|	&ArticleAP_AccountingObject                      AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	RevaluationTable.AccountingObject              AS CorDimensionOfAssetsLiabilities,
	|	RevaluationTable.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                AS CorCompany,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationMa > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationMa - RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationMa > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationMa - RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationAC > 0
	|			THEN RevaluationTable.AmountOfMarkdownDepreciationAC - RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0 
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	(RevaluationTable.AmountOfMarkdownDepreciationMa - RevaluationTable.DepreciationRevaluationReserve) > 0
	|				AND RevaluationTable.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|		OR (RevaluationTable.AmountOfMarkdownDepreciationAC - RevaluationTable.DepreciationRevaluationReserveLocal) > 0
	|				AND RevaluationTable.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	#Region Markdown_ReductionOfDepreciationDueToAdditionalValuation 
	QueryText =
	"SELECT
	|	DocumentData.Ref                     AS Recorder,
	|	DocumentData.Period                     AS Period,
	|	&HO_ReductionOfDepreciationDueToAdditionalValuation    AS BusinessOperation,
	|	DocumentData.Organization                AS Organization,
	|
	|	DocumentData.Department              AS Department,
	|	RevaluationTable.LineOfBusiness  AS LineOfBusiness,
	|	&ArticleAP_AccountingObject                      AS AssetRef,
	|	UNDEFINED                               AS DimensionOfRevenue,
	|	UNDEFINED                               AS DimensionOfExpenses,
	|	RevaluationTable.AccountingObject              AS AssetsLiabilitiesDimension,
	|	RevaluationTable.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	DocumentData.Department              AS DebitBusinessUnit,
	|	RevaluationTable.LineOfBusiness  AS CorLineOfBusiness,
	|	&ArticleAP_AccountingObject                      AS CorItem,
	|	UNDEFINED                               AS CorIncomeDimension,
	|	UNDEFINED                               AS CorExpenditureDimension,
	|	RevaluationTable.AccountingObject              AS CorDimensionOfAssetsLiabilities,
	|	RevaluationTable.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization                AS CorCompany,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationMa > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationMa > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN RevaluationTable.AmountOfMarkdownDepreciationAC > 0 AND RevaluationTable.DepreciationRevaluationReserveLocal > 0
	|			THEN RevaluationTable.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	RevaluationTable.AmountOfMarkdownDepreciationMa > 0 AND RevaluationTable.DepreciationRevaluationReserve > 0
	|		OR RevaluationTable.AmountOfMarkdownDepreciationAC > 0 AND RevaluationTable.DepreciationRevaluationReserveLocal > 0";
	CurRequestTexts.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(CurRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableRevaluationImpairment(Query, QueryTexts, KindOfAccountingObjects, DocumentName, Registers)
	
	RegisterName = "ImpairmentFA";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTTRevaluationTable(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	
	#Region RecoverImpairmentLoss
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.Department               AS Department,
	|	RevaluationTable.AccountingObject               AS NonCurrentAsset,
	|	RevaluationTable.CGU                      AS CGU,
	|	RevaluationTable.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	RevaluationTable.LineOfBusiness   AS LineOfBusiness,
	|
	|	RevaluationTable.ReserveForRevaluationOfImpairmentMan AS ImpairmenMan,
	|	RevaluationTable.ImpairmentRevaluationReserveLocal AS ImpairmentLocalAssets,
	|
	|	&BO_RecoverImpairmentLoss AS BusinessOperation,
	|	RevaluationTable.FinRecordID AS FinRecordID,
	|	&SettingUpBT_RecoveryOfImpairmentLoss AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN RevaluationTable AS RevaluationTable
	|		ON DocumentData.Ref = RevaluationTable.Ref
	|
	|WHERE
	|	(RevaluationTable.ReserveForRevaluationOfImpairmentMan <> 0
	|		OR RevaluationTable.ImpairmentRevaluationReserveLocal <> 0)
	|";
		
	#EndRegion

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTTRevaluationTable(Query, QueryTexts, KindOfAccountingObjects, DocumentName)
	
	TableName = "RevaluationTable";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTRevaluationOfCost(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTRevaluationOfDepreciation(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTRecoveryOfImpairmentLoss(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTCostRevaluationReserve(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTRevaluationDepreciationReserve(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTMethodOfRevaluation(QueryTexts, KindOfAccountingObjects);
	QueryTextTableTTRevaluationParameters(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	
	If KindOfAccountingObjects = "FA" Then
		QueryTextTableTTAccountingFA(QueryTexts);
		QueryTextTableTTLocationOfFA(QueryTexts);
	Else
		QueryTextTableTTAccountingProcedureForIA(QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentTable.AccountingObject AS AccountingObject,
	|	DocumentTable.RowID AS FinRecordID,
	|
	|	AccountingProcedure.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	AccountingProcedure.LineOfBusiness AS LineOfBusiness,
	|
	|	TTMethodOfRevaluation.ManSRevaluationMethod AS ManSRevaluationMethod,
	|	TTMethodOfRevaluation.LocalRevaluationMethod AS LocalRevaluationMethod,
	|
	|	ISNULL(TTRevaluationOfDepreciation.AccrueDepreciation, FALSE) AS AccrueDepreciation,
	|	ISNULL(TTRecoveryOfImpairmentLoss.CGU, UNDEFINED) AS CGU,
	|
	|	ISNULL(TTRevaluationOfCost.AmountOfMASAdditionalAssessment, 0)   AS AmountOfAdditionalAssessmentOfCostOfMa,
	|	ISNULL(TTRevaluationOfCost.AmountOfAdditionalACAssessment, 0)   AS AmountOfAdditionalAssessmentOfCostOfAC,
	|	ISNULL(TTRevaluationOfCost.AmountOfMarkdownMA, 0)     AS AmountOfMaMarkdown,
	|	ISNULL(TTRevaluationOfCost.AmountOfACMarkdown, 0)     AS AmountOfACCostMarkdown,
	|	ISNULL(TTRevaluationOfCost.AmountOfTFMarkdown, 0)     AS AmountOfDiscountOnCostOfCF,
	|	
	|	ISNULL(TTRevaluationOfDepreciation.AmountOfMASAdditionalAssessment, 0) AS AmountOfAdditionalAssessmentOfMaDepreciation,
	|	ISNULL(TTRevaluationOfDepreciation.AmountOfAdditionalACAssessment, 0) AS AmountOfAdditionalAssessmentOfACDepreciation,
	|	ISNULL(TTRevaluationOfDepreciation.AmountOfMarkdownMA, 0)   AS AmountOfMarkdownDepreciationMa,
	|	ISNULL(TTRevaluationOfDepreciation.AmountOfACMarkdown, 0)   AS AmountOfMarkdownDepreciationAC,
	|	ISNULL(TTRevaluationOfDepreciation.AmountOfTFMarkdown, 0)   AS AmountOfMarkdownDepreciationCF,
	|
	|	ISNULL(TTCostRevaluationReserve.SumMan, 0)    AS CostRevaluationReserve,
	|	ISNULL(TTCostRevaluationReserve.SumCompl, 0)   AS CostRevaluationReserveLocal,
	|
	|	ISNULL(TTRevaluationDepreciationReserve.SumMan, 0)  AS DepreciationRevaluationReserve,
	|	ISNULL(TTRevaluationDepreciationReserve.SumCompl, 0) AS DepreciationRevaluationReserveLocal,
	|
	|	ISNULL(TTRecoveryOfImpairmentLoss.SumMan, 0)  AS ReserveForRevaluationOfImpairmentMan,
	|	ISNULL(TTRecoveryOfImpairmentLoss.SumCompl, 0) AS ImpairmentRevaluationReserveLocal,
	|
	|	ISNULL(TTRevaluationParameters.BookCostOfMA, 0) AS BookCostOfMA,
	|	ISNULL(TTRevaluationParameters.BookCostOfAC, 0) AS BookCostOfAC,
	|
	|	ISNULL(TTRevaluationParameters.CoefficientOfAdditionalAssessmentOfMA, 0) AS CoefficientOfAdditionalAssessmentOfMA,
	|	ISNULL(TTRevaluationParameters.ACReEvaluationCoefficient, 0) AS ACReEvaluationCoefficient,
	|	
	|	ISNULL(TTRevaluationParameters.MAMarkdownRate, 0) AS MAMarkdownRate,
	|	ISNULL(TTRevaluationParameters.ACMarkdownFactor, 0) AS ACMarkdownFactor,
	|	
	|	ISNULL(TTRevaluationParameters.RevaluationReserveRatioMA, 0) AS RevaluationReserveRatioMA,
	|	ISNULL(TTRevaluationParameters.CoefficientOfRevaluationReserveAC, 0) AS CoefficientOfRevaluationReserveAC
	|
	|INTO RevaluationTable
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentTable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTRevaluationOfCost AS TTRevaluationOfCost
	|		ON TTRevaluationOfCost.Ref = DocumentTable.Ref
	|			AND TTRevaluationOfCost.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTRevaluationOfDepreciation AS TTRevaluationOfDepreciation
	|		ON TTRevaluationOfDepreciation.Ref = DocumentTable.Ref
	|			AND TTRevaluationOfDepreciation.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTCostRevaluationReserve AS TTCostRevaluationReserve
	|		ON TTCostRevaluationReserve.Ref = DocumentTable.Ref
	|			AND TTCostRevaluationReserve.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTRevaluationDepreciationReserve AS TTRevaluationDepreciationReserve
	|		ON TTRevaluationDepreciationReserve.Ref = DocumentTable.Ref
	|			AND TTRevaluationDepreciationReserve.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTRecoveryOfImpairmentLoss AS TTRecoveryOfImpairmentLoss
	|		ON TTRecoveryOfImpairmentLoss.Ref = DocumentTable.Ref
	|			AND TTRecoveryOfImpairmentLoss.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS AccountingProcedure
	|		ON AccountingProcedure.Ref = DocumentTable.Ref
	|			AND AccountingProcedure.FixedAsset = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TTRevaluationParameters AS TTRevaluationParameters
	|		ON TTRevaluationParameters.Ref = DocumentTable.Ref
	|			AND TTRevaluationParameters.AccountingObject = &FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|";
			
	ReplaceQueryTextParametersWhenReevaluating(QueryText, KindOfAccountingObjects, DocumentName);

	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

// Calculates how the cost changes - an additional estimate or markdown
//
Procedure QueryTextTableTTRevaluationOfCost(Query, QueryTexts, KindOfAccountingObjects, DocumentName)
	
	TableName = "TTRevaluationOfCost";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextEmptyTableBNACost(Query, QueryTexts);
	QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	ImpairmentFAServer.QueryTextEmptyTableDepreciationIn(Query, QueryTexts);
	QueryTextTableTTMethodOfRevaluation(QueryTexts, KindOfAccountingObjects);
	QueryTextTableTTCostAfterRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	
	ListOfRequests = New Array;
		
	#Region ProportionalRecalculationMethod
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|
		// Additional assessment of the cost of the UU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR TTMethodOfRevaluation.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN 0
	|
	|		WHEN ISNULL(TTCostAfterRevaluation.CostInManagementAccounting, 0) > ISNULL(CostOfVNA.Cost, 0)
	|
	|			THEN ISNULL(TTCostAfterRevaluation.CostInManagementAccounting, 0) 
	|					- ISNULL(CostOfVNA.Cost, 0)
	|
	|		ELSE 0 
	|
	|	END AS AmountOfMASAdditionalAssessment,
	|
		// Re-evaluation of the cost of BU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR TTMethodOfRevaluation.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN 0
	|
	|		WHEN ISNULL(TTCostAfterRevaluation.CostInAccounting, 0) > (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	|
	|			THEN ISNULL(TTCostAfterRevaluation.CostInAccounting, 0) 
	|					- ISNULL(CostOfVNA.LocalCost, 0) 
	|					- ISNULL(CostOfVNA.CostTargetFinancing, 0)
	|				
	|		ELSE 0 
	|
	|	END AS AmountOfAdditionalACAssessment,
	|	
		// Markdown of the cost of the UU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR TTMethodOfRevaluation.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|				OR ISNULL(CostOfVNA.Cost, 0) = 0
	|
	|			THEN 0
	|
	|		WHEN ISNULL(TTCostAfterRevaluation.CostInManagementAccounting, 0) < ISNULL(CostOfVNA.Cost, 0)
	|
	|			THEN ISNULL(CostOfVNA.Cost, 0) 
	|					- ISNULL(TTCostAfterRevaluation.CostInManagementAccounting, 0) 
	|
	|		ELSE 0 
	|
	|	END AS AmountOfMarkdownMA,
	|
		// Markdown of the cost of BU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR TTMethodOfRevaluation.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|				OR (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = 0
	|
	|			THEN 0
	|
	|		WHEN ISNULL(TTCostAfterRevaluation.CostInAccounting, 0) < (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	|
	|			THEN ISNULL(CostOfVNA.LocalCost, 0) 
	|					+ ISNULL(CostOfVNA.CostTargetFinancing, 0) 
	|					- ISNULL(TTCostAfterRevaluation.CostInAccounting, 0)
	|
	|		ELSE 0 
	|
	|	END AS AmountOfACMarkdown,
	|	
		// Markdown of the cost of CF
	|	0 AS AmountOfTFMarkdown
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|		INNER JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentTable.Ref
	|			AND CostOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TTCostAfterRevaluation AS TTCostAfterRevaluation
	|		ON TTCostAfterRevaluation.Ref = DocumentTable.Ref
	|			AND TTCostAfterRevaluation.AccountingObject = &FixedAsset
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|		AND TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|	OR DocumentData.RecordInLocalAccounting
	|		AND TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region CashMethod
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|
		// Additional assessment of the cost of the UU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR CostOfVNA.AccountingObject IS NULL
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|			THEN 0
	|
	|		WHEN ISNULL(TTCostAfterRevaluation.CostInManagementAccounting, 0) > (ISNULL(CostOfVNA.Cost, 0) 
	|																		- ISNULL(DepreciationOfVNA.Depreciation, 0))
	|
	|			THEN ISNULL(TTCostAfterRevaluation.CostInManagementAccounting, 0) 
	|					- ISNULL(CostOfVNA.Cost, 0)
	|					+ ISNULL(DepreciationOfVNA.Depreciation, 0)
	|
	|		ELSE 0 
	|
	|	END AS AmountOfMASAdditionalAssessment,
	|
		// Re-evaluation of the cost of BU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR CostOfVNA.AccountingObject IS NULL
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|			THEN 0
	|
	|		WHEN ISNULL(TTCostAfterRevaluation.CostInAccounting, 0) > (ISNULL(CostOfVNA.LocalCost, 0) 
	|																		+ ISNULL(CostOfVNA.CostTargetFinancing, 0)
	|																		- ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|																		- ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0))
	|
	|			THEN ISNULL(TTCostAfterRevaluation.CostInAccounting, 0)
	|					- ISNULL(CostOfVNA.LocalCost, 0) 
	|					- ISNULL(CostOfVNA.CostTargetFinancing, 0)
	|					+ ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|					+ ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)
	|				
	|		ELSE 0 
	|
	|	END AS AmountOfAdditionalACAssessment,
	|	
		// Markdown of the cost of the UU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR CostOfVNA.AccountingObject IS NULL
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|			THEN 0
	|
	|		WHEN ISNULL(TTCostAfterRevaluation.CostInManagementAccounting, 0) < (ISNULL(CostOfVNA.Cost, 0) 
	|																		- ISNULL(DepreciationOfVNA.Depreciation, 0))
	|
	|			THEN ISNULL(CostOfVNA.Cost, 0) 
	|					- ISNULL(DepreciationOfVNA.Depreciation, 0)
	|					- ISNULL(TTCostAfterRevaluation.CostInManagementAccounting, 0) 
	|
	|		ELSE 0 
	|
	|	END AS AmountOfMarkdownMA,
	|
		// Markdown of the cost of BU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR CostOfVNA.AccountingObject IS NULL
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|			THEN 0
	|
	|		WHEN ISNULL(TTCostAfterRevaluation.CostInAccounting, 0) < (ISNULL(CostOfVNA.LocalCost, 0) 
	|																		+ ISNULL(CostOfVNA.CostTargetFinancing, 0)
	|																		- ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|																		- ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0))
	|
	|			THEN ISNULL(CostOfVNA.LocalCost, 0) 
	|					+ ISNULL(CostOfVNA.CostTargetFinancing, 0) 
	|					- ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|					- ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)
	|					- ISNULL(TTCostAfterRevaluation.CostInAccounting, 0)
	|
	|		ELSE 0 
	|
	|	END AS AmountOfACMarkdown,
	|	
		// Markdown of the cost of CF
	|	0 AS AmountOfTFMarkdown
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|		INNER JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentTable.Ref
	|			AND CostOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentTable.Ref
	|			AND DepreciationOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TTCostAfterRevaluation AS TTCostAfterRevaluation
	|		ON TTCostAfterRevaluation.Ref = DocumentTable.Ref
	|			AND TTCostAfterRevaluation.AccountingObject = &FixedAsset
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|			AND TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|		OR DocumentData.RecordInLocalAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|			AND TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	QueryTextUnion = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText =
	"SELECT
	|	RevaluationTable.Ref AS Ref,
	|	RevaluationTable.AccountingObject AS AccountingObject,
	|
	|	SUM(RevaluationTable.AmountOfMASAdditionalAssessment) AS AmountOfMASAdditionalAssessment,
	|	SUM(RevaluationTable.AmountOfAdditionalACAssessment) AS AmountOfAdditionalACAssessment,
	|	
	|	SUM(RevaluationTable.AmountOfMarkdownMA) AS AmountOfMarkdownMA,
	|	SUM(RevaluationTable.AmountOfACMarkdown) AS AmountOfACMarkdown,
	|	SUM(RevaluationTable.AmountOfTFMarkdown) AS AmountOfTFMarkdown
	|	
	|
	|INTO TTRevaluationOfCost
	|	
	|FROM
	|	&RevaluationTable AS RevaluationTable
	|
	|GROUP BY
	|	RevaluationTable.Ref,
	|	RevaluationTable.AccountingObject
	|
	|HAVING
	|	SUM(RevaluationTable.AmountOfMASAdditionalAssessment) <> 0
	|		OR SUM(RevaluationTable.AmountOfAdditionalACAssessment) <> 0
	|		OR SUM(RevaluationTable.AmountOfMarkdownMA) <> 0
	|		OR SUM(RevaluationTable.AmountOfACMarkdown) <> 0
	|		OR SUM(RevaluationTable.AmountOfTFMarkdown) <> 0
	|	
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|";
	
	QueryText = StrReplace(QueryText, "&RevaluationTable", "(" + QueryTextUnion + ")");
	
	ReplaceQueryTextParametersWhenReevaluating(QueryText, KindOfAccountingObjects, DocumentName);
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

// Calculates how depreciation changes - additional valuation or markdown
//
Procedure QueryTextTableTTRevaluationOfDepreciation(Query, QueryTexts, KindOfAccountingObjects, DocumentName)
	
	TableName = "TTRevaluationOfDepreciation";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextEmptyTableBNACost(Query, QueryTexts);
	QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	ImpairmentFAServer.QueryTextEmptyTableDepreciationIn(Query, QueryTexts);
	QueryTextTableTTMethodOfRevaluation(QueryTexts, KindOfAccountingObjects);
	QueryTextTableTTCostAfterRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTDepreciationAfterRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	
	ListOfRequests = New Array;
	
	#Region MethodOfProportionalRecalculationByReplacementCost
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|
	|	ISNULL(DepreciationOfVNA.AccrueDepreciation, FALSE) AS AccrueDepreciation,
	|
	// Additional assessment of depreciation of the UU
	|	CASE 
	|		WHEN NOT (DocumentData.RecordInManAccounting
	|					AND (NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|							OR TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|									AND NOT DocumentData.RevaluateAtFairValue))
	|
	|			THEN 0
	|
	|		WHEN DocumentTable.CostInManagementAccounting > ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) = ISNULL(DepreciationOfVNA.Depreciation, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|
	|			THEN DocumentTable.CostInManagementAccounting - ISNULL(CostOfVNA.Cost, 0)
	|
	|		WHEN DocumentTable.CostInManagementAccounting > ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|				AND ISNULL(DepreciationOfVNA.Depreciation, 0) <> 0
	|
	|			THEN -DepreciationOfVNA.Depreciation
	|					+ CAST(DepreciationOfVNA.Depreciation 
	|									* CAST(CAST(DocumentTable.CostInManagementAccounting AS NUMBER(31,10)) / CAST(ISNULL(CostOfVNA.Cost, 0) AS NUMBER(31,10)) AS NUMBER(31,10)) AS NUMBER(31,2))
	|
	|		ELSE 0 
	|
	|	END AS AmountOfMASAdditionalAssessment,
	|
	// Additional assessment of BU depreciation
	|	CASE 
	|		WHEN NOT (DocumentData.RecordInLocalAccounting
	|					AND (NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|							OR TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|								AND NOT DocumentData.RevaluateAtFairValue))
	|
	|			THEN 0
	|
	|		WHEN DocumentTable.CostInAccounting > ISNULL(CostOfVNA.LocalCost, 0)
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) <> 0
	|
	|			THEN DocumentTable.CostInAccounting - (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	|
	|		WHEN DocumentTable.CostInAccounting > ISNULL(CostOfVNA.LocalCost, 0)
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) <> 0
	|				AND (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)) <> 0
	|
	|			THEN -(DepreciationOfVNA.DepreciationLocal + DepreciationOfVNA.FixedAssetDepreciationTargetFinancing) 
	|					+ CAST((DepreciationOfVNA.DepreciationLocal + DepreciationOfVNA.FixedAssetDepreciationTargetFinancing)
	|									* CAST(CAST(DocumentTable.CostInAccounting AS NUMBER(31,10)) / CAST(ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0) AS NUMBER(31,10)) AS NUMBER(31,10)) AS NUMBER(31,2))
	|
	|		ELSE 0 
	|
	|	END AS AmountOfAdditionalACAssessment,
	|	
	// Depreciation markdown of the UU
	|	CASE 
	|		WHEN NOT (DocumentData.RecordInManAccounting
	|					AND (NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|							OR TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|									AND NOT DocumentData.RevaluateAtFairValue))
	|
	|			THEN 0
	|
	|		WHEN DocumentTable.CostInManagementAccounting < ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) = ISNULL(DepreciationOfVNA.Depreciation, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|
	|			THEN ISNULL(CostOfVNA.Cost, 0) - DocumentTable.CostInManagementAccounting
	|
	|		WHEN DocumentTable.CostInManagementAccounting < ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|
	|			THEN DepreciationOfVNA.Depreciation
	|					- CAST(DepreciationOfVNA.Depreciation 
	|									* CAST(CAST(DocumentTable.CostInManagementAccounting AS NUMBER(31,10)) / CAST(ISNULL(CostOfVNA.Cost, 0) AS NUMBER(31,10)) AS NUMBER(31,10)) AS NUMBER(31,2))
	|
	|		ELSE 0 
	|
	|	END AS AmountOfMarkdownMA,
	|
	// Depreciation markdown BU
	|	CASE 
	|		WHEN NOT (DocumentData.RecordInLocalAccounting
	|					AND (NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|							OR TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|								AND NOT DocumentData.RevaluateAtFairValue))
	|
	|			THEN 0
	|
	|		WHEN DocumentTable.CostInAccounting < (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) <> 0
	|
	|			THEN ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0) 
	|					- DocumentTable.CostInAccounting
	|
	|		WHEN DocumentTable.CostInAccounting < (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) <> 0
	|
	|			THEN (DepreciationOfVNA.DepreciationLocal + DepreciationOfVNA.FixedAssetDepreciationTargetFinancing) 
	|					- CAST((DepreciationOfVNA.DepreciationLocal + DepreciationOfVNA.FixedAssetDepreciationTargetFinancing)
	|									* CAST(CAST(DocumentTable.CostInAccounting AS NUMBER(31,10)) / CAST(ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0) AS NUMBER(31,10)) AS NUMBER(31,10)) AS NUMBER(31,2)) 
	|		ELSE 0 
	|
	|	END AS AmountOfACMarkdown,
	|
	// Depreciation markdown of CF
	|	CASE 
	|		WHEN NOT (DocumentData.RecordInLocalAccounting
	|					AND (NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|							OR TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|								AND NOT DocumentData.RevaluateAtFairValue)) 
	|				OR (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = 0
	|				OR DocumentTable.CostInAccounting < (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	|				OR ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|
	|			THEN 0
	|
	|		WHEN (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) <> 0
	|				AND ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0) > DocumentTable.CostInAccounting
	|
	|			THEN DepreciationOfVNA.FixedAssetDepreciationTargetFinancing - DocumentTable.CostInAccounting
	|
	|		WHEN DepreciationOfVNA.FixedAssetDepreciationTargetFinancing > CAST((DepreciationOfVNA.DepreciationLocal + DepreciationOfVNA.FixedAssetDepreciationTargetFinancing)
	|												* (DocumentTable.CostInAccounting / (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))) AS NUMBER(31,2))
	|			THEN DepreciationOfVNA.FixedAssetDepreciationTargetFinancing 
	|					- CAST((DepreciationOfVNA.DepreciationLocal + DepreciationOfVNA.FixedAssetDepreciationTargetFinancing)
	|									* (DocumentTable.CostInAccounting / (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))) AS NUMBER(31,2)) 
	|		ELSE 0 
	|
	|	END AS AmountOfTFMarkdown
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentTable.Ref
	|			AND CostOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentTable.Ref
	|			AND DepreciationOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|WHERE
	|	NOT CostOfVNA.AccountingObject IS NULL
	|	AND (DocumentData.RecordInManAccounting
	|			AND (NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|					OR TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|							AND NOT DocumentData.RevaluateAtFairValue)
	|		OR DocumentData.RecordInLocalAccounting
	|			AND (NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|					OR TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|							AND NOT DocumentData.RevaluateAtFairValue))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region MethodOfProportionalRecalculationAtFairCost
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|
	|	ISNULL(DepreciationOfVNA.AccrueDepreciation, FALSE) AS AccrueDepreciation,
	|
		// Additional assessment of depreciation of the UU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN 0
	|
			// Re-evaluation of a fully self-certified object
	|		WHEN ISNULL(TTCostAfterRevaluation.CostInManagementAccounting, 0) > ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) = ISNULL(DepreciationOfVNA.Depreciation, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|
	|			THEN ISNULL(TTCostAfterRevaluation.CostInManagementAccounting, 0) - ISNULL(CostOfVNA.Cost, 0)
	| 
	|		WHEN ISNULL(TTDepreciationAfterRevaluation.DepreciationManagementAccounting, 0) > ISNULL(DepreciationOfVNA.Depreciation, 0)
	|
	|			THEN ISNULL(TTDepreciationAfterRevaluation.DepreciationManagementAccounting, 0) 
	|					- ISNULL(DepreciationOfVNA.Depreciation, 0)
	| 
	|		ELSE 0 
	|
	|	END AS AmountOfMASAdditionalAssessment,
	|
		// Additional assessment of BU depreciation
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN 0
	|
			// Re-evaluation of a fully self-certified object
	|		WHEN ISNULL(TTCostAfterRevaluation.CostInAccounting, 0) > (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) <> 0
	|
	|			THEN ISNULL(TTCostAfterRevaluation.CostInAccounting, 0) - (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	| 
	|		WHEN ISNULL(TTDepreciationAfterRevaluation.DepreciationInAccounting, 0) > (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0))
	|
	|			THEN ISNULL(TTDepreciationAfterRevaluation.DepreciationInAccounting, 0) 
	|					- ISNULL(DepreciationOfVNA.DepreciationLocal, 0) 
	|					- ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)
	| 
	|		ELSE 0 
	|
	|	END AS AmountOfAdditionalACAssessment,
	|	
		// Depreciation markdown of the UU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN 0
	|
			// Markdown of a fully amortized object
	|		WHEN DocumentTable.CostInManagementAccounting < ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) = ISNULL(DepreciationOfVNA.Depreciation, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|
	|			THEN ISNULL(CostOfVNA.Cost, 0) - DocumentTable.CostInManagementAccounting
	| 
	|		WHEN ISNULL(TTDepreciationAfterRevaluation.DepreciationManagementAccounting, 0) < ISNULL(DepreciationOfVNA.Depreciation, 0)
	|
	|			THEN ISNULL(DepreciationOfVNA.Depreciation, 0)
	|					- ISNULL(TTDepreciationAfterRevaluation.DepreciationManagementAccounting, 0)
	| 
	|		ELSE 0 
	|
	|	END AS AmountOfMarkdownMA,
	|
		// Depreciation markdown BU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN 0
	|
			// Markdown of a fully amortized object
	|		WHEN DocumentTable.CostInAccounting < (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) <> 0
	|
	|			THEN ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0) 
	|					- DocumentTable.CostInAccounting
	| 
	|		WHEN ISNULL(TTDepreciationAfterRevaluation.DepreciationInAccounting, 0) < (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0))
	|
	|			THEN ISNULL(DepreciationOfVNA.DepreciationLocal, 0) 
	|					+ ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)
	|					- ISNULL(TTDepreciationAfterRevaluation.DepreciationInAccounting, 0)
	|
	|		ELSE 0 
	|
	|	END AS AmountOfACMarkdown,
	|
		// Depreciation markdown of CF
	|	0 AS AmountOfTFMarkdown
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentTable.Ref
	|			AND CostOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentTable.Ref
	|			AND DepreciationOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TTCostAfterRevaluation AS TTCostAfterRevaluation
	|		ON TTCostAfterRevaluation.Ref = DocumentTable.Ref
	|			AND TTCostAfterRevaluation.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTDepreciationAfterRevaluation AS TTDepreciationAfterRevaluation
	|		ON TTDepreciationAfterRevaluation.Ref = DocumentTable.Ref
	|			AND TTDepreciationAfterRevaluation.AccountingObject = &FixedAsset
	|
	|WHERE
	|	NOT CostOfVNA.AccountingObject IS NULL
	|	AND DocumentData.RevaluateAtFairValue
	|	AND (DocumentData.RecordInManAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|			AND TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|		OR DocumentData.RecordInLocalAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|			AND TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region CashMethod
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|
	|	ISNULL(DepreciationOfVNA.AccrueDepreciation, FALSE) AS AccrueDepreciation,
	|
	|	0 AS AmountOfMASAdditionalAssessment,
	|	0 AS AmountOfAdditionalACAssessment,
	|
		// AmountOfMarkdownMA
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|			THEN 0
	|
	|		ELSE ISNULL(DepreciationOfVNA.Depreciation, 0)
	|
	|	END AS AmountOfMarkdownMA,
	|
		// AmountOfACMarkdown
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|			THEN 0
	|
	|		ELSE ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|
	|	END AS AmountOfACMarkdown,
	|
		// AmountOfTFMarkdown
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|			THEN 0
	|
	|		ELSE ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)
	|
	|	END AS AmountOfTFMarkdown
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentTable.Ref
	|			AND DepreciationOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|WHERE
	|	NOT DepreciationOfVNA.AccountingObject IS NULL
	|	AND (DocumentData.RecordInManAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|			AND TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|		OR DocumentData.RecordInLocalAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|			AND TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region BeforeFASWasApplied
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|
	|	ISNULL(DepreciationOfVNA.AccrueDepreciation, FALSE) AS AccrueDepreciation,
	|
	// Additional assessment of depreciation of the UU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting
	|				OR ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|
	|			THEN 0
	|
	|		WHEN DocumentTable.CostInManagementAccounting > ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) = ISNULL(DepreciationOfVNA.Depreciation, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|
	|			THEN DocumentTable.CostInManagementAccounting - ISNULL(CostOfVNA.Cost, 0)
	|
	|		WHEN DocumentTable.CostInManagementAccounting > ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|				AND ISNULL(DepreciationOfVNA.Depreciation, 0) <> 0
	|
	|			THEN -DepreciationOfVNA.Depreciation
	|					+ CAST(DepreciationOfVNA.Depreciation 
	|									* CAST(CAST(DocumentTable.CostInManagementAccounting AS NUMBER(31,10)) / CAST(ISNULL(CostOfVNA.Cost, 0) AS NUMBER(31,10)) AS NUMBER(31,10)) AS NUMBER(31,2))
	|
	|		ELSE 0 
	|
	|	END AS AmountOfMASAdditionalAssessment,
	|
	// Additional assessment of BU depreciation
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting
	|				OR ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|
	|			THEN 0
	|
	|		WHEN DocumentTable.CostInAccounting > ISNULL(CostOfVNA.LocalCost, 0)
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) <> 0
	|
	|			THEN DocumentTable.CostInAccounting - (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	|
	|		WHEN DocumentTable.CostInAccounting > ISNULL(CostOfVNA.LocalCost, 0)
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) <> 0
	|				AND (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)) <> 0
	|
	|			THEN -(DepreciationOfVNA.DepreciationLocal + DepreciationOfVNA.FixedAssetDepreciationTargetFinancing) 
	|					+ CAST((DepreciationOfVNA.DepreciationLocal + DepreciationOfVNA.FixedAssetDepreciationTargetFinancing)
	|									* CAST(CAST(DocumentTable.CostInAccounting AS NUMBER(31,10)) / CAST(ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0) AS NUMBER(31,10)) AS NUMBER(31,10)) AS NUMBER(31,2))
	|
	|		ELSE 0 
	|
	|	END AS AmountOfAdditionalACAssessment,
	|	
	// Depreciation markdown of the UU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting
	|				OR ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|
	|			THEN 0
	|
	|		WHEN DocumentTable.CostInManagementAccounting < ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) = ISNULL(DepreciationOfVNA.Depreciation, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|
	|			THEN ISNULL(CostOfVNA.Cost, 0) - DocumentTable.CostInManagementAccounting
	|
	|		WHEN DocumentTable.CostInManagementAccounting < ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|
	|			THEN DepreciationOfVNA.Depreciation
	|					- CAST(DepreciationOfVNA.Depreciation 
	|									* CAST(CAST(DocumentTable.CostInManagementAccounting AS NUMBER(31,10)) / CAST(ISNULL(CostOfVNA.Cost, 0) AS NUMBER(31,10)) AS NUMBER(31,10)) AS NUMBER(31,2))
	|
	|		ELSE 0 
	|
	|	END AS AmountOfMarkdownMA,
	|
	// Depreciation markdown BU
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting
	|				OR ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|
	|			THEN 0
	|
	|		WHEN DocumentTable.CostInAccounting < (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) <> 0
	|
	|			THEN ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0) 
	|					- DocumentTable.CostInAccounting
	|
	|		WHEN DocumentTable.CostInAccounting < (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) <> 0
	|
	|			THEN (DepreciationOfVNA.DepreciationLocal + DepreciationOfVNA.FixedAssetDepreciationTargetFinancing) 
	|					- CAST((DepreciationOfVNA.DepreciationLocal + DepreciationOfVNA.FixedAssetDepreciationTargetFinancing)
	|									* CAST(CAST(DocumentTable.CostInAccounting AS NUMBER(31,10)) / CAST(ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0) AS NUMBER(31,10)) AS NUMBER(31,10)) AS NUMBER(31,2)) 
	|		ELSE 0 
	|
	|	END AS AmountOfACMarkdown,
	|
	// Depreciation markdown of CF
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting
	|				OR ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|				OR (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = 0
	|				OR DocumentTable.CostInAccounting < (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))
	|
	|			THEN 0
	|
	|		WHEN (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0))
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) <> 0
	|				AND ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0) > DocumentTable.CostInAccounting
	|
	|			THEN DepreciationOfVNA.FixedAssetDepreciationTargetFinancing - DocumentTable.CostInAccounting
	|
	|		WHEN DepreciationOfVNA.FixedAssetDepreciationTargetFinancing > CAST((DepreciationOfVNA.DepreciationLocal + DepreciationOfVNA.FixedAssetDepreciationTargetFinancing)
	|												* (DocumentTable.CostInAccounting / (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))) AS NUMBER(31,2))
	|			THEN DepreciationOfVNA.FixedAssetDepreciationTargetFinancing 
	|					- CAST((DepreciationOfVNA.DepreciationLocal + DepreciationOfVNA.FixedAssetDepreciationTargetFinancing)
	|									* (DocumentTable.CostInAccounting / (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0))) AS NUMBER(31,2)) 
	|		ELSE 0 
	|
	|	END AS AmountOfTFMarkdown
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentTable.Ref
	|			AND CostOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentTable.Ref
	|			AND DepreciationOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|WHERE
	|	NOT CostOfVNA.AccountingObject IS NULL
	|	AND (DocumentData.RecordInManAccounting
	|			AND NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|		OR DocumentData.RecordInLocalAccounting
	|			AND NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	QueryTextUnion = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
			
	QueryText =
	"SELECT
	|	RevaluationTable.Ref AS Ref,
	|	RevaluationTable.AccountingObject AS AccountingObject,
	|	RevaluationTable.AccrueDepreciation AS AccrueDepreciation,
	|
	|	SUM(RevaluationTable.AmountOfMASAdditionalAssessment) AS AmountOfMASAdditionalAssessment,
	|	SUM(RevaluationTable.AmountOfAdditionalACAssessment) AS AmountOfAdditionalACAssessment,
	|
	|	SUM(RevaluationTable.AmountOfMarkdownMA) AS AmountOfMarkdownMA,
	|	SUM(RevaluationTable.AmountOfACMarkdown) AS AmountOfACMarkdown,
	|	SUM(RevaluationTable.AmountOfTFMarkdown) AS AmountOfTFMarkdown
	|
	|INTO TTRevaluationOfDepreciation
	|	
	|FROM
	|	&RevaluationTable AS RevaluationTable
	|
	|GROUP BY
	|	RevaluationTable.Ref,
	|	RevaluationTable.AccountingObject,
	|	RevaluationTable.AccrueDepreciation
	|
	|HAVING
	|	SUM(RevaluationTable.AmountOfMASAdditionalAssessment) <> 0
	|		OR SUM(RevaluationTable.AmountOfAdditionalACAssessment) <> 0
	|		OR SUM(RevaluationTable.AmountOfMarkdownMA) <> 0
	|		OR SUM(RevaluationTable.AmountOfACMarkdown) <> 0
	|		OR SUM(RevaluationTable.AmountOfTFMarkdown) <> 0
	|	
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|";
	
	QueryText = StrReplace(QueryText, "&RevaluationTable", "(" + QueryTextUnion + ")");
	
	ReplaceQueryTextParametersWhenReevaluating(QueryText, KindOfAccountingObjects, DocumentName);
			
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTCostRevaluationReserve(Query, QueryTexts, KindOfAccountingObjects, DocumentName)
	
	TableName = "TTCostRevaluationReserve";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextEmptyTableBNACost(Query, QueryTexts);
	QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	ImpairmentFAServer.QueryTextEmptyTableDepreciationIn(Query, QueryTexts);
	QueryTextTableTTMethodOfRevaluation(QueryTexts, KindOfAccountingObjects);
	QueryTextTableTTRevaluationParameters(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTRevaluationOfCost(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTRevaluationOfDepreciation(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTRecoveryOfImpairmentLoss(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	
	ListOfRequests = New Array;
	
	#Region RevaluationToFAS
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|
		// SumMan
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR CostOfVNA.AccountingObject IS NULL
	|				OR ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|
	|			THEN 0
	|
			// Additional assessment, there is a markdown reserve, additional assessment of the markdown < reserve 
	|		WHEN DocumentTable.CostInManagementAccounting > ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.CostRevaluationReserve, 0) < 0
	|				AND (DocumentTable.CostInManagementAccounting - ISNULL(CostOfVNA.Cost, 0)) < -ISNULL(CostOfVNA.CostRevaluationReserve, 0)
	|				
	|			THEN DocumentTable.CostInManagementAccounting - ISNULL(CostOfVNA.Cost, 0)
	|
			// Additional estimate, there is a markdown reserve, additional estimate >= markdown reserve 
	|		WHEN DocumentTable.CostInManagementAccounting > ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.CostRevaluationReserve, 0) < 0
	|				AND (DocumentTable.CostInManagementAccounting - ISNULL(CostOfVNA.Cost, 0)) >= -ISNULL(CostOfVNA.CostRevaluationReserve, 0)
	|				
	|			THEN -ISNULL(CostOfVNA.CostRevaluationReserve, 0)
	|
			// Markdown, there is a reserve for additional valuation, markdown < reserve for additional valuation 
	|		WHEN DocumentTable.CostInManagementAccounting < ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.CostRevaluationReserve, 0) > 0
	|				AND (ISNULL(CostOfVNA.Cost, 0) - DocumentTable.CostInManagementAccounting) < ISNULL(CostOfVNA.CostRevaluationReserve, 0)
	|				
	|			THEN ISNULL(CostOfVNA.Cost, 0) - DocumentTable.CostInManagementAccounting
	|
			// Markdown, there is an additional valuation reserve, markdown >= additional valuation reserve 
	|		WHEN DocumentTable.CostInManagementAccounting < ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.CostRevaluationReserve, 0) > 0
	|				AND (ISNULL(CostOfVNA.Cost, 0) - DocumentTable.CostInManagementAccounting) >= ISNULL(CostOfVNA.CostRevaluationReserve, 0)
	|				
	|			THEN ISNULL(CostOfVNA.CostRevaluationReserve, 0)
	|
	|		ELSE 0
	|
	|	END AS SumMan,
	|
		// SumCompl
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR CostOfVNA.AccountingObject IS NULL
	|				OR ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|
	|			THEN 0
	|
			// Additional assessment, there is a markdown reserve, additional assessment of the markdown < reserve 
	|		WHEN DocumentTable.CostInAccounting > ISNULL(CostOfVNA.LocalCost, 0)
	|				AND ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) < 0
	|				AND (DocumentTable.CostInAccounting - ISNULL(CostOfVNA.LocalCost, 0)) < -ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0)
	|				
	|			THEN DocumentTable.CostInAccounting - ISNULL(CostOfVNA.LocalCost, 0)
	|
			// Additional estimate, there is a markdown reserve, additional estimate >= markdown reserve 
	|		WHEN DocumentTable.CostInAccounting > ISNULL(CostOfVNA.LocalCost, 0)
	|				AND ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) < 0
	|				AND (DocumentTable.CostInAccounting - ISNULL(CostOfVNA.LocalCost, 0)) >= -ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0)
	|				
	|			THEN -ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0)
	|
			// Markdown, there is a reserve for additional valuation, markdown < reserve for additional valuation 
	|		WHEN DocumentTable.CostInAccounting < ISNULL(CostOfVNA.LocalCost, 0)
	|				AND ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) > 0
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) - DocumentTable.CostInAccounting) < ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0)
	|				
	|			THEN ISNULL(CostOfVNA.LocalCost, 0) - DocumentTable.CostInAccounting
	|
			// Markdown, there is an additional valuation reserve, markdown >= additional valuation reserve 
	|		WHEN DocumentTable.CostInAccounting < ISNULL(CostOfVNA.LocalCost, 0)
	|				AND ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) > 0
	|				AND (ISNULL(CostOfVNA.LocalCost, 0) - DocumentTable.CostInAccounting) >= ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0)
	|				
	|			THEN ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0)
	|
	|		ELSE 0
	|
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentTable.Ref
	|			AND CostOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentTable.Ref
	|			AND DepreciationOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|		OR DocumentData.RecordInLocalAccounting
	|			AND NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ProportionalRecalculationMethod
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|	
		// SumMan
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR ISNULL(TTRevaluationParameters.ReserveForRevaluationOfMACost, 0) = 0
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN 0
	|
			// Additional assessment, there is a reserve for markdowns, Additional assessment < Reserve 
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) > 0
	|				AND ISNULL(TTRevaluationParameters.ReserveForRevaluationOfMACost, 0) < 0
	|				AND (ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) 
	|					- ISNULL(TTRecoveryOfImpairmentLoss.SumMan, 0)) < -ISNULL(TTRevaluationParameters.ReserveForRevaluationOfBookCostOfMA, 0)
	|				
	|			THEN CAST((ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) 
	|								- ISNULL(TTRecoveryOfImpairmentLoss.SumMan, 0))
	|					/ (1 - ISNULL(TTRevaluationParameters.RevaluationReserveRatioMA, 0)) AS NUMBER(31, 2))
	|
			// Additional estimate, there is a markdown reserve, Additional estimate >= Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) > 0
	|				AND ISNULL(TTRevaluationParameters.ReserveForRevaluationOfMACost, 0) < 0
	|				AND (ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) 
	|					- ISNULL(TTRecoveryOfImpairmentLoss.SumMan, 0)) >= -ISNULL(TTRevaluationParameters.ReserveForRevaluationOfBookCostOfMA, 0)
	|				
	|			THEN -ISNULL(TTRevaluationParameters.ReserveForRevaluationOfMACost, 0)
	|
			// Markdown, there is a reserve for additional assessment, Markdown < Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < 0
	|				AND ISNULL(TTRevaluationParameters.ReserveForRevaluationOfMACost, 0) > 0
	|				AND -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < ISNULL(TTRevaluationParameters.ReserveForRevaluationOfBookCostOfMA, 0)
	|				
	|			THEN -CAST(ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0)
	|					/ (1 - ISNULL(TTRevaluationParameters.RevaluationReserveRatioMA, 0)) AS NUMBER(31, 2))
	|
			// Markdown, there is a reserve for additional valuation, Markdown >= Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < 0
	|				AND ISNULL(TTRevaluationParameters.ReserveForRevaluationOfMACost, 0) > 0
	|				AND -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) >= ISNULL(TTRevaluationParameters.ReserveForRevaluationOfBookCostOfMA, 0)
	|				
	|			THEN ISNULL(TTRevaluationParameters.ReserveForRevaluationOfMACost, 0)
	|
	|		ELSE 0
	|
	|	END AS SumMan,
	|
		// SumCompl
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR ISNULL(TTRevaluationParameters.RevaluationReserveForACCosts, 0) = 0
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN 0
	|
			// Additional assessment, there is a reserve for markdowns, Additional assessment < Reserve 
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) > 0
	|				AND ISNULL(TTRevaluationParameters.RevaluationReserveForACCosts, 0) < 0
	|				AND (ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) 
	|					- ISNULL(TTRecoveryOfImpairmentLoss.SumCompl, 0)) < -ISNULL(TTRevaluationParameters.RevaluationReserveForBookCostOfAC, 0)
	|				
	|			THEN CAST((ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) 
	|								- ISNULL(TTRecoveryOfImpairmentLoss.SumCompl, 0))
	|					/ (1 - ISNULL(TTRevaluationParameters.CoefficientOfRevaluationReserveAC, 0)) AS NUMBER(31, 2))
	|
			// Additional estimate, there is a markdown reserve, Additional estimate >= Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) > 0
	|				AND ISNULL(TTRevaluationParameters.RevaluationReserveForACCosts, 0) < 0
	|				AND (ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) 
	|					- ISNULL(TTRecoveryOfImpairmentLoss.SumCompl, 0)) >= -ISNULL(TTRevaluationParameters.RevaluationReserveForBookCostOfAC, 0)
	|				
	|			THEN -ISNULL(TTRevaluationParameters.RevaluationReserveForACCosts, 0)
	|
			// Markdown, there is a reserve for additional assessment, Markdown < Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < 0
	|				AND ISNULL(TTRevaluationParameters.RevaluationReserveForACCosts, 0) > 0
	|				AND -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < ISNULL(TTRevaluationParameters.RevaluationReserveForBookCostOfAC, 0)
	|				
	|			THEN -CAST(ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0)
	|					/ (1 - ISNULL(TTRevaluationParameters.CoefficientOfRevaluationReserveAC, 0)) AS NUMBER(31, 2))
	|
			// Markdown, there is a reserve for additional valuation, Markdown >= Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < 0
	|				AND ISNULL(TTRevaluationParameters.RevaluationReserveForACCosts, 0) > 0
	|				AND -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) >= ISNULL(TTRevaluationParameters.RevaluationReserveForBookCostOfAC, 0)
	|				
	|			THEN ISNULL(TTRevaluationParameters.RevaluationReserveForACCosts, 0)
	|
	|		ELSE 0
	|
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TTRevaluationOfCost AS TTRevaluationOfCost
	|		ON TTRevaluationOfCost.Ref = DocumentTable.Ref
	|			AND TTRevaluationOfCost.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTRevaluationOfDepreciation AS TTRevaluationOfDepreciation
	|		ON TTRevaluationOfDepreciation.Ref = DocumentTable.Ref
	|			AND TTRevaluationOfDepreciation.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTRecoveryOfImpairmentLoss AS TTRecoveryOfImpairmentLoss
	|		ON TTRecoveryOfImpairmentLoss.Ref = DocumentTable.Ref
	|			AND TTRecoveryOfImpairmentLoss.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TTRevaluationParameters AS TTRevaluationParameters
	|		ON TTRevaluationParameters.Ref = DocumentTable.Ref
	|			AND TTRevaluationParameters.AccountingObject = &FixedAsset
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|			AND TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|		OR DocumentData.RecordInLocalAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|			AND TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region CashMethod
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|	
		// SumMan
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR ISNULL(CostOfVNA.CostRevaluationReserve, 0) = 0
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|			THEN 0
	|
			// Additional assessment, there is a reserve for markdowns, Additional assessment < Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) > 0
	|				AND ISNULL(CostOfVNA.CostRevaluationReserve, 0) < 0
	|				AND (ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) 
	|					- ISNULL(TTRecoveryOfImpairmentLoss.SumMan, 0)) > 0
	|				AND (ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) 
	|					- ISNULL(TTRecoveryOfImpairmentLoss.SumMan, 0)) < -ISNULL(CostOfVNA.CostRevaluationReserve, 0)
	|				
	|			THEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) - ISNULL(TTRecoveryOfImpairmentLoss.SumMan, 0)
	|
			// Additional estimate, there is a markdown reserve, Additional estimate >= Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) > 0
	|				AND ISNULL(CostOfVNA.CostRevaluationReserve, 0) < 0
	|				AND (ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) 
	|					- ISNULL(TTRecoveryOfImpairmentLoss.SumMan, 0)) > 0
	|				AND (ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) 
	|					- ISNULL(TTRecoveryOfImpairmentLoss.SumMan, 0)) >= -ISNULL(CostOfVNA.CostRevaluationReserve, 0)
	|				
	|			THEN -ISNULL(CostOfVNA.CostRevaluationReserve, 0)
	|
			// Markdown, there is a reserve for additional valuation, Markdown < Reserve: Reserve = Markdown
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < 0
	|				AND ISNULL(CostOfVNA.CostRevaluationReserve, 0) > 0
	|				AND -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < ISNULL(CostOfVNA.CostRevaluationReserve, 0)
	|				
	|			THEN -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0)
	|
			// Markdown, there is an additional valuation reserve, Markdown >= Reserve: Reserve = Additional valuation Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < 0
	|				AND ISNULL(CostOfVNA.CostRevaluationReserve, 0) > 0
	|				AND -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) >= ISNULL(CostOfVNA.CostRevaluationReserve, 0)
	|				
	|			THEN ISNULL(CostOfVNA.CostRevaluationReserve, 0)
	|
	|		ELSE 0
	|
	|	END AS SumMan,
	|
		// SumCompl
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) = 0
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|			THEN 0
	|
			// Additional assessment, there is a reserve for markdowns, Additional assessment < Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) > 0
	|				AND ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) < 0
	|				AND (ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) 
	|					- ISNULL(TTRecoveryOfImpairmentLoss.SumCompl, 0)) > 0
	|				AND (ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) 
	|					- ISNULL(TTRecoveryOfImpairmentLoss.SumCompl, 0)) < -ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0)
	|				
	|			THEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) - ISNULL(TTRecoveryOfImpairmentLoss.SumCompl, 0)
	|
			// Additional estimate, there is a markdown reserve, Additional estimate >= Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) > 0
	|				AND ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) < 0
	|				AND (ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) 
	|					- ISNULL(TTRecoveryOfImpairmentLoss.SumCompl, 0)) > 0
	|				AND (ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) 
	|					- ISNULL(TTRecoveryOfImpairmentLoss.SumCompl, 0)) >= -ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0)
	|				
	|			THEN -ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0)
	|
			// Markdown, there is a reserve for additional valuation, Markdown < Reserve: Reserve = Markdown
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < 0
	|				AND ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) > 0
	|				AND -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0)
	|				
	|			THEN -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0)
	|
			// Markdown, there is an additional valuation reserve, Markdown >= Reserve: Reserve = Additional valuation Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < 0
	|				AND ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) > 0
	|				AND -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) >= ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0)
	|				
	|			THEN ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0)
	|
	|		ELSE 0
	|
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentTable.Ref
	|			AND CostOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTRecoveryOfImpairmentLoss AS TTRecoveryOfImpairmentLoss
	|		ON TTRecoveryOfImpairmentLoss.Ref = DocumentTable.Ref
	|			AND TTRecoveryOfImpairmentLoss.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TTRevaluationParameters AS TTRevaluationParameters
	|		ON TTRevaluationParameters.Ref = DocumentTable.Ref
	|			AND TTRevaluationParameters.AccountingObject = &FixedAsset
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|			AND TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|			AND ISNULL(CostOfVNA.CostRevaluationReserve, 0) <> 0
	|
	|		OR DocumentData.RecordInLocalAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|			AND TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod))
	|			AND ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) <> 0
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	QueryTextUnion = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText =
	"SELECT
	|	RevaluationTable.Ref AS Ref,
	|	RevaluationTable.AccountingObject AS AccountingObject,
	|
	|	SUM(RevaluationTable.SumMan) AS SumMan,
	|	SUM(RevaluationTable.SumCompl) AS SumCompl
	|
	|INTO TTCostRevaluationReserve
	|	
	|FROM
	|	&RevaluationTable AS RevaluationTable
	|
	|GROUP BY
	|	RevaluationTable.Ref,
	|	RevaluationTable.AccountingObject
	|	
	|HAVING
	|	SUM(RevaluationTable.SumMan) <> 0
	|		OR SUM(RevaluationTable.SumCompl) <> 0
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|";
	
	QueryText = StrReplace(QueryText, "&RevaluationTable", "(" + QueryTextUnion + ")");
	
	ReplaceQueryTextParametersWhenReevaluating(QueryText, KindOfAccountingObjects, DocumentName);
			
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTRevaluationDepreciationReserve(Query, QueryTexts, KindOfAccountingObjects, DocumentName)
	
	TableName = "TTRevaluationDepreciationReserve";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextEmptyTableBNACost(Query, QueryTexts);
	QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	ImpairmentFAServer.QueryTextEmptyTableDepreciationIn(Query, QueryTexts);
	QueryTextTableTTMethodOfRevaluation(QueryTexts, KindOfAccountingObjects);
	QueryTextTableTTRevaluationParameters(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTRevaluationOfCost(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTRevaluationOfDepreciation(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	QueryTextTableTTCostRevaluationReserve(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	
	ListOfRequests = New Array;
	
	#Region RevaluationToFAS
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|
		// SumMan
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR CostOfVNA.AccountingObject IS NULL
	|				OR ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|
	|			THEN 0
	|
			// Additional assessment and reserve > Additional assessments: Reserve = Additional assessment
	|		WHEN DocumentTable.CostInManagementAccounting > ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|				AND ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0) < 0
	|				AND (-DepreciationOfVNA.Depreciation
	|					+ CAST(DepreciationOfVNA.Depreciation
	|						* (DocumentTable.CostInManagementAccounting / ISNULL(CostOfVNA.Cost, 0)) AS NUMBER(31,2))) < -ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0)
	|				
	|			THEN -DepreciationOfVNA.Depreciation
	|					+ CAST(DepreciationOfVNA.Depreciation * (DocumentTable.CostInManagementAccounting / ISNULL(CostOfVNA.Cost, 0)) AS NUMBER(31,2))
	|
			// Additional assessment and reserve <= additional assessment: Reserve = Reserve
	|		WHEN DocumentTable.CostInManagementAccounting > ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|				AND ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0) < 0
	|				AND (-DepreciationOfVNA.Depreciation
	|					+ CAST(DepreciationOfVNA.Depreciation
	|							* (DocumentTable.CostInManagementAccounting / ISNULL(CostOfVNA.Cost, 0)) AS NUMBER(31,2))) >= -ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0)
	|				
	|			THEN -ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0)
	|
			// Markdown and Reserve > Markdowns: Reserve = Markdown
	|		WHEN DocumentTable.CostInManagementAccounting < ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(CostOfVNA.Cost, 0) <> 0
	|				AND ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0) > 0
	|				AND (DepreciationOfVNA.Depreciation
	|					- CAST(DepreciationOfVNA.Depreciation 
	|								* (DocumentTable.CostInManagementAccounting / ISNULL(CostOfVNA.Cost, 0)) AS NUMBER(31,2))) < ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0)
	|				
	|			THEN DepreciationOfVNA.Depreciation
	|					- CAST(DepreciationOfVNA.Depreciation * (DocumentTable.CostInManagementAccounting / ISNULL(CostOfVNA.Cost, 0)) AS NUMBER(31,2))
	|
			// Markdown and reserve <= Markdowns: Reserve = Reserve
	|		WHEN DocumentTable.CostInManagementAccounting < ISNULL(CostOfVNA.Cost, 0)
	|				AND ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0) > 0
	|				AND (DepreciationOfVNA.Depreciation
	|					- CAST(DepreciationOfVNA.Depreciation 
	|								* (DocumentTable.CostInManagementAccounting / ISNULL(CostOfVNA.Cost, 0)) AS NUMBER(31,2))) >= ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0)
	|				
	|			THEN ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0)
	|
	|		ELSE 0
	|
	|	END AS SumMan,
	|
		// SumCompl
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR CostOfVNA.AccountingObject IS NULL
	|				OR ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|
	|			THEN 0
	|
			// Additional assessment and reserve > Additional assessments: Reserve = Additional assessment
	|		WHEN DocumentTable.CostInAccounting > ISNULL(CostOfVNA.LocalCost, 0)
	|				AND ISNULL(CostOfVNA.LocalCost, 0) <> 0
	|				AND ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0) < 0
	|				AND (-DepreciationOfVNA.DepreciationLocal
	|					+ CAST(DepreciationOfVNA.DepreciationLocal 
	|								* (DocumentTable.CostInAccounting / ISNULL(CostOfVNA.LocalCost, 0)) AS NUMBER(31,2))) < -ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0)
	|				
	|			THEN -DepreciationOfVNA.DepreciationLocal
	|					+ CAST(DepreciationOfVNA.DepreciationLocal * (DocumentTable.CostInAccounting / ISNULL(CostOfVNA.LocalCost, 0)) AS NUMBER(31,2))
	|
			// Additional assessment and reserve <= additional assessment: Reserve = Reserve
	|		WHEN DocumentTable.CostInAccounting > ISNULL(CostOfVNA.LocalCost, 0)
	|				AND ISNULL(CostOfVNA.LocalCost, 0) <> 0
	|				AND ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0) < 0
	|				AND (-DepreciationOfVNA.DepreciationLocal
	|					+ CAST(DepreciationOfVNA.DepreciationLocal 
	|								* (DocumentTable.CostInAccounting / ISNULL(CostOfVNA.LocalCost, 0)) AS NUMBER(31,2))) >= -ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0)
	|				
	|			THEN -ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0)
	|
			// Markdown and Reserve > Markdowns: Reserve = Markdown
	|		WHEN DocumentTable.CostInAccounting < ISNULL(CostOfVNA.LocalCost, 0)
	|				AND ISNULL(CostOfVNA.LocalCost, 0) <> 0
	|				AND ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0) > 0
	|				AND (DepreciationOfVNA.DepreciationLocal
	|					- CAST(DepreciationOfVNA.DepreciationLocal 
	|								* (DocumentTable.CostInAccounting / ISNULL(CostOfVNA.LocalCost, 0)) AS NUMBER(31,2))) < ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0)
	|				
	|			THEN DepreciationOfVNA.DepreciationLocal
	|					- CAST(DepreciationOfVNA.DepreciationLocal * (DocumentTable.CostInAccounting / ISNULL(CostOfVNA.LocalCost, 0)) AS NUMBER(31,2))
	|
			// Markdown and reserve <= Markdowns: Reserve = Reserve
	|		WHEN DocumentTable.CostInAccounting < ISNULL(CostOfVNA.LocalCost, 0)
	|				AND ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0) > 0
	|				AND (DepreciationOfVNA.DepreciationLocal
	|					- CAST(DepreciationOfVNA.DepreciationLocal 
	|								* (DocumentTable.CostInAccounting / ISNULL(CostOfVNA.LocalCost, 0)) AS NUMBER(31,2))) >= ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0)
	|				
	|			THEN ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0)
	|
	|		ELSE 0
	|
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentTable.Ref
	|			AND CostOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentTable.Ref
	|			AND DepreciationOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|		OR DocumentData.RecordInLocalAccounting
	|			AND NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ProportionalRecalculationMethod
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|
		// SumMan
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0) = 0
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.ManSRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN 0
	|
			// Additional valuation, there is a markdown reserve, (Additional cost estimate - Additional depreciation estimate) < (Cost reserve - Depreciation Reserve) 
	|		WHEN ISNULL(TTRevaluationOfCost.AmountOfMASAdditionalAssessment, 0) - ISNULL(TTRecoveryOfImpairmentLoss.SumMan, 0) > 0
	|				AND ISNULL(TTRevaluationParameters.ReserveForRevaluationOfBookCostOfMA, 0) < 0
	|				AND (ISNULL(TTRevaluationOfCost.AmountOfMASAdditionalAssessment, 0) - ISNULL(TTRevaluationOfDepreciation.AmountOfMASAdditionalAssessment, 0)) < -ISNULL(TTRevaluationParameters.ReserveForRevaluationOfBookCostOfMA, 0)
	|				
	|			THEN CAST(ISNULL(TTCostRevaluationReserve.SumMan, 0)
	|					* ISNULL(TTRevaluationParameters.RevaluationReserveRatioMA, 0) AS NUMBER(31, 2))
	|
			// Additional assessment, reserve < 0, Additional assessment >= Reserve: Reserve = Reserve
	|		WHEN ISNULL(TTRevaluationOfDepreciation.AmountOfMASAdditionalAssessment, 0) > 0
	|				AND ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0) < 0
	|				AND ISNULL(TTRevaluationOfDepreciation.AmountOfMASAdditionalAssessment, 0) >= -ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0)
	|				
	|			THEN -ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0)
	|
			// Additional assessment, reserve < 0, Additional assessment < Reserve: Reserve = Additional assessment
	|		WHEN ISNULL(TTRevaluationOfDepreciation.AmountOfMASAdditionalAssessment, 0) > 0
	|				AND ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0) < 0
	|				AND ISNULL(TTRevaluationOfDepreciation.AmountOfMASAdditionalAssessment, 0) < -ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0)
	|				
	|			THEN ISNULL(TTRevaluationOfDepreciation.AmountOfMASAdditionalAssessment, 0)
	|
			// Markdown, reserve > 0, Markdown >= Reserve : Reserve = Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < 0
	|				AND -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) >= ISNULL(TTRevaluationParameters.ReserveForRevaluationOfBookCostOfMA, 0)
	|				
	|			THEN ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0)
	|
			// Markdown, Reserve > 0, Markdown < Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < 0
	|				AND -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < ISNULL(TTRevaluationParameters.ReserveForRevaluationOfBookCostOfMA, 0)
	|				
	|			THEN CAST(ISNULL(TTCostRevaluationReserve.SumMan, 0)
	|					* ISNULL(TTRevaluationParameters.RevaluationReserveRatioMA, 0) AS NUMBER(31, 2))
	|
	|		ELSE 0
	|
	|	END AS SumMan,
	|
		// SumCompl
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0) = 0
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|				OR TTMethodOfRevaluation.LocalRevaluationMethod <> VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN 0
	|
			// Additional valuation, there is a markdown reserve, (Additional cost estimate - Additional depreciation estimate) < (Cost reserve - Depreciation Reserve) 
	|		WHEN ISNULL(TTRevaluationOfCost.AmountOfAdditionalACAssessment, 0) - ISNULL(TTRecoveryOfImpairmentLoss.SumCompl, 0) > 0
	|				AND ISNULL(TTRevaluationParameters.RevaluationReserveForBookCostOfAC, 0) < 0
	|				AND (ISNULL(TTRevaluationOfCost.AmountOfAdditionalACAssessment, 0) - ISNULL(TTRevaluationOfDepreciation.AmountOfAdditionalACAssessment, 0)) < -ISNULL(TTRevaluationParameters.RevaluationReserveForBookCostOfAC, 0)
	|				
	|			THEN CAST(ISNULL(TTCostRevaluationReserve.SumCompl, 0)
	|					* ISNULL(TTRevaluationParameters.CoefficientOfRevaluationReserveAC, 0) AS NUMBER(31, 2))
	|
			// Additional valuation, there is a markdown reserve, Additional valuation >= Reserve: Reserve = Markdown Reserve
	|		WHEN ISNULL(TTRevaluationOfDepreciation.AmountOfAdditionalACAssessment, 0) > 0
	|				AND ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0) < 0
	|				AND ISNULL(TTRevaluationOfDepreciation.AmountOfAdditionalACAssessment, 0) >= -ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0)
	|				
	|			THEN -ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0)
	|
			// Additional valuation, there is a markdown reserve, Additional valuation < Reserve: Reserve = Additional valuation
	|		WHEN ISNULL(TTRevaluationOfDepreciation.AmountOfAdditionalACAssessment, 0) > 0
	|				AND ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0) < 0
	|				AND ISNULL(TTRevaluationOfDepreciation.AmountOfAdditionalACAssessment, 0) < -ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0)
	|				
	|			THEN ISNULL(TTRevaluationOfDepreciation.AmountOfAdditionalACAssessment, 0)
	|
			// Markdown, there is an additional valuation reserve, Markdown >= Reserve : Reserve = Additional valuation Reserve
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < 0
	|				AND -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) >= ISNULL(TTRevaluationParameters.RevaluationReserveForBookCostOfAC, 0)
	|				
	|			THEN ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0)
	|
			// Markdown, there is a reserve for additional valuation, Markdown < Reserve : Reserve = Markdown
	|		WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < 0
	|				AND -ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < ISNULL(TTRevaluationParameters.RevaluationReserveForBookCostOfAC, 0)
	|				
	|			THEN CAST(ISNULL(TTCostRevaluationReserve.SumCompl, 0)
	|					* ISNULL(TTRevaluationParameters.CoefficientOfRevaluationReserveAC, 0) AS NUMBER(31, 2))
	|
	|		ELSE 0
	|
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentTable.Ref
	|			AND DepreciationOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTRevaluationOfCost AS TTRevaluationOfCost
	|		ON TTRevaluationOfCost.Ref = DocumentTable.Ref
	|			AND TTRevaluationOfCost.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTRevaluationOfDepreciation AS TTRevaluationOfDepreciation
	|		ON TTRevaluationOfDepreciation.Ref = DocumentTable.Ref
	|			AND TTRevaluationOfDepreciation.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTRecoveryOfImpairmentLoss AS TTRecoveryOfImpairmentLoss
	|		ON TTRecoveryOfImpairmentLoss.Ref = DocumentTable.Ref
	|			AND TTRecoveryOfImpairmentLoss.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTCostRevaluationReserve AS TTCostRevaluationReserve
	|		ON TTCostRevaluationReserve.Ref = DocumentTable.Ref
	|			AND TTCostRevaluationReserve.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTRevaluationParameters AS TTRevaluationParameters
	|		ON TTRevaluationParameters.Ref = DocumentTable.Ref
	|			AND TTRevaluationParameters.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|			AND TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|		OR DocumentData.RecordInLocalAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|			AND TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	QueryTextUnion = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
			
	QueryText =
	"SELECT
	|	RevaluationTable.Ref AS Ref,
	|	RevaluationTable.AccountingObject AS AccountingObject,
	|
	|	SUM(RevaluationTable.SumMan) AS SumMan,
	|	SUM(RevaluationTable.SumCompl) AS SumCompl
	|
	|INTO TTRevaluationDepreciationReserve
	|	
	|FROM
	|	&RevaluationTable AS RevaluationTable
	|
	|GROUP BY
	|	RevaluationTable.Ref,
	|	RevaluationTable.AccountingObject
	|	
	|HAVING
	|	SUM(RevaluationTable.SumMan) <> 0
	|		OR SUM(RevaluationTable.SumCompl) <> 0
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|";
	
	QueryText = StrReplace(QueryText, "&RevaluationTable", "(" + QueryTextUnion + ")");
	
	ReplaceQueryTextParametersWhenReevaluating(QueryText, KindOfAccountingObjects, DocumentName);

	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTRecoveryOfImpairmentLoss(Query, QueryTexts, KindOfAccountingObjects, DocumentName)
	
	TableName = "TTRecoveryOfImpairmentLoss";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	ImpairmentFAServer.QueryTextEmptyTableDepreciationIn(Query, QueryTexts);
	QueryTextTableTTRevaluationParameters(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	&FixedAsset AS AccountingObject,
	|	ImpairmentFA.CGU AS CGU,
	|
		// SumMan
	|	CASE 
	|		WHEN NOT DocumentData.RecordInManAccounting 
	|				OR ISNULL(ImpairmentFA.ImpairmenMan, 0) = 0
	|				OR ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) <= 0
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|
	|			THEN 0
	|
			// Additional assessment, there is an impairment, Additional assessment < Impairment: Loss to recover = Additional valuation
	|		WHEN ISNULL(ImpairmentFA.ImpairmenMan, 0) > 0
	|				AND ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < ISNULL(ImpairmentFA.ImpairmenMan, 0)
	|				
	|			THEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0)
	|
			// Additional assessment, there is an impairment, Additional assessment >= Impairment: Loss to recovery = Impairment
	|		WHEN ISNULL(ImpairmentFA.ImpairmenMan, 0) > 0
	|				AND ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) >= ISNULL(ImpairmentFA.ImpairmenMan, 0)
	|				
	|			THEN ISNULL(ImpairmentFA.ImpairmenMan, 0)
	|
	|		ELSE 0
	|
	|	END AS SumMan,
	|
		// SumCompl
	|	CASE 
	|		WHEN NOT DocumentData.RecordInLocalAccounting 
	|				OR ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) = 0
	|				OR ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) <= 0
	|				OR NOT ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|
	|			THEN 0
	|
			// Additional assessment, there is an impairment, Additional assessment < Impairment: Reserve = Additional valuation
	|		WHEN ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) > 0
	|				AND ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0)
	|				
	|			THEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0)
	|
			// Additional assessment, there is an impairment, Additional assessment >= Impairment: Reserve = Impairment
	|		WHEN ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) > 0
	|				AND ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) >= ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0)
	|				
	|			THEN ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0)
	|
	|		ELSE 0
	|
	|	END AS SumCompl
	|
	|INTO TTRecoveryOfImpairmentLoss
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentData.Ref = DocumentTable.Ref
	|
	|		INNER JOIN TT_ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Ref = DocumentTable.Ref
	|			AND ImpairmentFA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTRevaluationParameters AS TTRevaluationParameters
	|		ON TTRevaluationParameters.Ref = DocumentTable.Ref
	|			AND TTRevaluationParameters.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseManSRevaluationMethod, FALSE)
	|			AND ISNULL(ImpairmentFA.ImpairmenMan, 0) <> 0
	|			AND ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) > 0
	|
	|		OR DocumentData.RecordInLocalAccounting
	|			AND ISNULL(TTMethodOfRevaluation.UseLocalRevaluationMethod, FALSE)
	|			AND ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) <> 0
	|			AND ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) > 0)
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|";
	
	ReplaceQueryTextParametersWhenReevaluating(QueryText, KindOfAccountingObjects, DocumentName);
			
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTMethodOfRevaluation(QueryTexts, KindOfAccountingObjects) Export
	
	TableName = "TTMethodOfRevaluation";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
	
	QueryText = NonCurrentAssetsLocalization.QueryTextTableTTMethodOfRevaluation(QueryTexts, KindOfAccountingObjects);
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Ref,
		|
		|	CASE
		|		WHEN ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS UseManSRevaluationMethod,
		|
		|	CASE
		|		WHEN ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS UseLocalRevaluationMethod,
		|
		|	CASE
		|		WHEN ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
		|			THEN ISNULL(AccountingPolicy.FixedAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod))
		|		ELSE VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
		|	END AS ManSRevaluationMethod,
		|
		|	CASE
		|		WHEN ISNULL(AccountingPolicy.AccountingPolicyForFixedAssets, VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)) = VALUE(Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards)
		|			THEN ISNULL(AccountingPolicy.FixedAssetRevaluationMethod, VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod))
		|		ELSE VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
		|	END AS LocalRevaluationMethod
		|
		|INTO TTMethodOfRevaluation
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPolicy
		|		ON AccountingPolicy.Ref = DocumentData.Ref
		|
		|INDEX BY
		|	Ref";
		
		If KindOfAccountingObjects = "IA" Then 
			QueryText = StrReplace(QueryText, "AccountingPolicy.FixedAssetRevaluationMethod", "AccountingPolicy.IntangibleAssetRevaluationMethod");
		EndIf;
	
	EndIf;

	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

// Calculates the cost that should be after the revaluation.
// - In case of revaluation by the method of proportional recalculation at replacement cost, it is equal to the cost indicated in the document.
// - When revalued by the method of proportional recalculation at fair cost, it changes by the coefficient = fair cost / book cost.
// - When revalued by the balance method, it is equal to the cost indicated in the document.
//
Procedure QueryTextTableTTCostAfterRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName)
	
	TableName = "TTCostAfterRevaluation";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryTextTableTTRevaluationParameters(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|
	// CostInManagementAccounting
	|	CASE
	|		WHEN NOT DocumentData.RevaluateAtFairValue
	|
	|			THEN DocumentTable.CostInManagementAccounting
	|
	|		WHEN TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|			THEN ISNULL(TTRevaluationParameters.FairCostMA, 0)
	|
	|		WHEN TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN CASE
	|					WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < 0
	|							AND ISNULL(TTRevaluationParameters.MAMarkdownRate, 0) <> 0
	|
	|						THEN CAST(TTRevaluationParameters.CostInManagementAccounting 
	|								- CAST(ISNULL(TTRevaluationParameters.MAMarkdownRate, 0)
	|									* (CAST(-TTRevaluationParameters.RevaluationOfBookCostOfMA AS NUMBER(31, 10))
	|											/ CAST(ISNULL(TTRevaluationParameters.MAMarkdownRate, 0) - 1 AS NUMBER(31, 10))) AS NUMBER(31, 10)) AS NUMBER(31, 2))
	|
	|					WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < 0
	|							AND ISNULL(TTRevaluationParameters.MAMarkdownRate, 0) = 0
	|
	|						THEN ISNULL(TTRevaluationParameters.FairCostMA, 0) 
	|
	|					ELSE CAST(ISNULL(TTRevaluationParameters.CostInManagementAccounting, 0)
	|							* ISNULL(TTRevaluationParameters.CoefficientOfAdditionalAssessmentOfMA, 0) AS NUMBER(31, 2))
	|				END
	|
	|		ELSE 0
	|
	|	END AS CostInManagementAccounting,
	|
	// CostInAccounting
	|	CASE
	|		WHEN NOT DocumentData.RevaluateAtFairValue
	|
	|			THEN DocumentTable.CostInAccounting
	|
	|		WHEN TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod)
	|
	|			THEN ISNULL(TTRevaluationParameters.FairCostOfAC, 0)
	|
	|		WHEN TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN CASE
	|					WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < 0
	|							AND ISNULL(TTRevaluationParameters.ACMarkdownFactor, 0) <> 0
	|
	|						THEN CAST(TTRevaluationParameters.CostInAccounting 
	|								- CAST(ISNULL(TTRevaluationParameters.ACMarkdownFactor, 0)
	|									* (CAST(-TTRevaluationParameters.RevaluationOfBookCostOfAC AS NUMBER(31, 10))
	|											/ CAST(ISNULL(TTRevaluationParameters.ACMarkdownFactor, 0) - 1 AS NUMBER(31, 10))) AS NUMBER(31, 10)) AS NUMBER(31, 2))
	|
	|					WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < 0
	|							AND ISNULL(TTRevaluationParameters.ACMarkdownFactor, 0) = 0
	|
	|						THEN ISNULL(TTRevaluationParameters.FairCostOfAC, 0)
	|
	|					ELSE CAST(ISNULL(TTRevaluationParameters.CostInAccounting, 0)
	|							* ISNULL(TTRevaluationParameters.ACReEvaluationCoefficient, 0) AS NUMBER(31, 2))
	|				END
	|
	|		ELSE 0
	|
	|	END AS CostInAccounting
	|
	|INTO TTCostAfterRevaluation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentTable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTRevaluationParameters AS TTRevaluationParameters
	|		ON TTRevaluationParameters.Ref = DocumentTable.Ref
	|			AND TTRevaluationParameters.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = DocumentTable.Ref
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|";
	
	ReplaceQueryTextParametersWhenReevaluating(QueryText, KindOfAccountingObjects, DocumentName);

	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

// Calculates the depreciation that should be after the revaluation.
// - In case of revaluation by the method of proportional recalculation at replacement cost, it is recalculated in proportion to the change in cost.
// - When revaluing by the method of proportional recalculation at fair cost, it changes by the coefficient = fair cost / book cost.
// - When revalued by the balance method, it is equal to zero.
//
Procedure QueryTextTableTTDepreciationAfterRevaluation(Query, QueryTexts, KindOfAccountingObjects, DocumentName)
	
	TableName = "TTDepreciationAfterRevaluation";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryTextTableTTRevaluationParameters(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	
	QueryText =
	"SELECT
	|	TTRevaluationParameters.Ref AS Ref,
	|	TTRevaluationParameters.AccountingObject AS AccountingObject,
	|
	// DepreciationManagementAccounting
	|	CASE
	|		WHEN TTMethodOfRevaluation.ManSRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN CASE
	|					WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < 0
	|							AND TTRevaluationParameters.MAMarkdownRate <> 0
	|
	|						THEN CAST(TTRevaluationParameters.DepreciationManagementAccounting 
	|								- CAST(CAST(-TTRevaluationParameters.RevaluationOfBookCostOfMA AS NUMBER(31, 10))
	|											/ CAST(TTRevaluationParameters.MAMarkdownRate - 1 AS NUMBER(31, 10)) AS NUMBER(31, 10)) AS NUMBER(31, 2))
	|
	|					WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfMA, 0) < 0
	|							AND TTRevaluationParameters.MAMarkdownRate = 0
	|
	|						THEN 0
	|
	|					ELSE CAST(ISNULL(TTRevaluationParameters.DepreciationManagementAccounting, 0)
	|							* ISNULL(TTRevaluationParameters.CoefficientOfAdditionalAssessmentOfMA, 0) AS NUMBER(31, 2))
	|				END
	|
	|		ELSE 0
	|
	|	END AS DepreciationManagementAccounting,
	|
	// DepreciationInAccounting
	|	CASE
	|		WHEN TTMethodOfRevaluation.LocalRevaluationMethod = VALUE(Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod)
	|
	|			THEN CASE
	|					WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < 0
	|							AND TTRevaluationParameters.ACMarkdownFactor <> 0
	|
	|						THEN CAST(TTRevaluationParameters.DepreciationInAccounting 
	|								- CAST(CAST(-TTRevaluationParameters.RevaluationOfBookCostOfAC AS NUMBER(31, 10))
	|											/ CAST(TTRevaluationParameters.ACMarkdownFactor - 1 AS NUMBER(31, 10)) AS NUMBER(31, 10)) AS NUMBER(31, 2))
	|
	|					WHEN ISNULL(TTRevaluationParameters.RevaluationOfBookCostOfAC, 0) < 0
	|							AND TTRevaluationParameters.ACMarkdownFactor = 0
	|
	|						THEN 0
	|
	|					ELSE CAST(ISNULL(TTRevaluationParameters.DepreciationInAccounting, 0)
	|							* ISNULL(TTRevaluationParameters.ACReEvaluationCoefficient, 0) AS NUMBER(31, 2))
	|				END
	|
	|		ELSE 0
	|
	|	END AS DepreciationInAccounting
	|
	|INTO TTDepreciationAfterRevaluation
	|
	|FROM
	|	TTRevaluationParameters AS TTRevaluationParameters
	|
	|		LEFT JOIN TTMethodOfRevaluation AS TTMethodOfRevaluation
	|		ON TTMethodOfRevaluation.Ref = TTRevaluationParameters.Ref
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTRevaluationParameters(Query, QueryTexts, KindOfAccountingObjects, DocumentName)
	
	TableName = "TTRevaluationParameters";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryTextEmptyTableBNACost(Query, QueryTexts);
	QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	ImpairmentFAServer.QueryTextEmptyTableDepreciationIn(Query, QueryTexts);
	QueryTextTableTTFairCost(Query, QueryTexts, KindOfAccountingObjects, DocumentName);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|
	|	ISNULL(CostOfVNA.Cost, 0) AS CostInManagementAccounting,
	|
	|	ISNULL(CostOfVNA.LocalCost, 0) 
	|		+ ISNULL(CostOfVNA.CostTargetFinancing, 0) AS CostInAccounting,
	|
	|	ISNULL(DepreciationOfVNA.Depreciation, 0) AS DepreciationManagementAccounting,
	|
	|	ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|		+ ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0) AS DepreciationInAccounting,
	|
	|	ISNULL(ImpairmentFA.ImpairmenMan, 0) AS ImpairmenMan,
	|	ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) AS ImpairmentLocalAssets,
	|
	// BookCostOfMA
	|	ISNULL(CostOfVNA.Cost, 0) 
	|		- ISNULL(DepreciationOfVNA.Depreciation, 0)
	|		- ISNULL(ImpairmentFA.ImpairmenMan, 0) AS BookCostOfMA,
	|
	// BookCostOfAC
	|	ISNULL(CostOfVNA.LocalCost, 0) 
	|		+ ISNULL(CostOfVNA.CostTargetFinancing, 0)
	|		- ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|		- ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)
	|		- ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) AS BookCostOfAC,
	|
	|	ISNULL(TTFairCost.CostInManagementAccounting, 0) AS FairCostMA,
	|	ISNULL(TTFairCost.CostInAccounting, 0) AS FairCostOfAC,
	|
	// RevaluationOfBookCostOfMA
	|	ISNULL(TTFairCost.CostInManagementAccounting, 0)
	|		- ISNULL(CostOfVNA.Cost, 0) 
	|		+ ISNULL(DepreciationOfVNA.Depreciation, 0)
	|		+ ISNULL(ImpairmentFA.ImpairmenMan, 0) AS RevaluationOfBookCostOfMA,
	|
	// RevaluationOfBookCostOfAC
	|	ISNULL(TTFairCost.CostInAccounting, 0)
	|		- ISNULL(CostOfVNA.LocalCost, 0) 
	|		- ISNULL(CostOfVNA.CostTargetFinancing, 0)
	|		+ ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|		+ ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)
	|		+ ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) AS RevaluationOfBookCostOfAC,
	|
	// CoefficientOfAdditionalAssessmentOfMA
	|	CASE
	|		WHEN ISNULL(CostOfVNA.Cost, 0) = 0
	|				OR (ISNULL(CostOfVNA.Cost, 0) 
	|						- ISNULL(DepreciationOfVNA.Depreciation, 0)) = 0
	|
	|			THEN 1
	|
	|		ELSE CAST(CAST(ISNULL(TTFairCost.CostInManagementAccounting, 0) AS NUMBER (31, 10))
	|							/ CAST(ISNULL(CostOfVNA.Cost, 0) 
	|										- ISNULL(DepreciationOfVNA.Depreciation, 0) AS NUMBER (31, 10)) AS NUMBER (31,10))
	|
	|	END AS CoefficientOfAdditionalAssessmentOfMA,
	|
	// ACReEvaluationCoefficient
	|	CASE
	|		WHEN (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = 0
	|				OR (ISNULL(CostOfVNA.LocalCost, 0) 
	|						+ ISNULL(CostOfVNA.CostTargetFinancing, 0)
	|						- ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|						- ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)) = 0
	|
	|			THEN 1
	|
	|		ELSE CAST(CAST(ISNULL(TTFairCost.CostInAccounting, 0) AS NUMBER(31,10))
	|							/ CAST(ISNULL(CostOfVNA.LocalCost, 0) 
	|								+ ISNULL(CostOfVNA.CostTargetFinancing, 0)
	|								- ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|								- ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0) AS NUMBER (31,10)) AS NUMBER (31,10))
	|
	|	END AS ACReEvaluationCoefficient,
	|
	// MAMarkdownRate
	|	CASE
	|		WHEN ISNULL(DepreciationOfVNA.Depreciation, 0) = 0
	|
	|			THEN 0
	|
	|		ELSE CAST(CAST(ISNULL(CostOfVNA.Cost, 0) AS NUMBER (31, 10))
	|							/ CAST(ISNULL(DepreciationOfVNA.Depreciation, 0) AS NUMBER (31, 10)) AS NUMBER (31,10))
	|
	|	END AS MAMarkdownRate,
	|
	// ACMarkdownFactor
	|	CASE
	|		WHEN (ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)) = 0
	|
	|			THEN 0
	|
	|		ELSE CAST(CAST(ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0) AS NUMBER(31,10))
	|							/ CAST(ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0) AS NUMBER (31,10)) AS NUMBER (31,10))
	|
	|	END AS ACMarkdownFactor,
	|
	|	ISNULL(CostOfVNA.CostRevaluationReserve, 0) AS ReserveForRevaluationOfMACost,
	|	ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) AS RevaluationReserveForACCosts,
	|
	|	ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0) AS RevaluationReserveForDepreciationMA,
	|	ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0) AS RevaluationReserveForDepreciationAC,
	|
	// RevaluationReserveRatioMA
	|	CASE
	|		WHEN ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0) = 0
	|				OR ISNULL(CostOfVNA.CostRevaluationReserve, 0) = 0
	|
	|			THEN 0
	|
	|		ELSE CAST(CAST(ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0) AS NUMBER (31,10))
	|							/ CAST(ISNULL(CostOfVNA.CostRevaluationReserve, 0) AS NUMBER (31,10)) AS NUMBER (31,10))
	|
	|	END AS RevaluationReserveRatioMA,
	|
	// CoefficientOfRevaluationReserveAC
	|	CASE
	|		WHEN ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) = 0
	|				OR ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) = 0
	|
	|			THEN 0
	|
	|		ELSE CAST(CAST(ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0) AS NUMBER (31,10))
	|							/ CAST(ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) AS NUMBER (31,10)) AS NUMBER (31,10))
	|
	|	END AS CoefficientOfRevaluationReserveAC,
	|
	// ReserveForRevaluationOfBookCostOfMA
	|	ISNULL(CostOfVNA.CostRevaluationReserve, 0) 
	|		- ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0) AS ReserveForRevaluationOfBookCostOfMA,
	|
	// RevaluationReserveForBookCostOfAC
	|	ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) 
	|		- ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0) AS RevaluationReserveForBookCostOfAC
	|
	|INTO TTRevaluationParameters
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentTable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFairCost AS TTFairCost
	|		ON TTFairCost.Ref = DocumentTable.Ref
	|			AND TTFairCost.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentTable.Ref
	|			AND CostOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentTable.Ref
	|			AND DepreciationOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TT_ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Ref = DocumentTable.Ref
	|			AND ImpairmentFA.AccountingObject = &FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|";
	
	ReplaceQueryTextParametersWhenReevaluating(QueryText, KindOfAccountingObjects, DocumentName);

	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTFairCost(Query, QueryTexts, KindOfAccountingObjects, DocumentName)

	TableName = "TTFairCost";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryTextEmptyTableBNACost(Query, QueryTexts);
	QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	ImpairmentFAServer.QueryTextEmptyTableDepreciationIn(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	&FixedAsset AS AccountingObject,
	|
	|	CASE
	|		WHEN NOT DocumentData.RecordInManAccounting
	|				OR ISNULL(CostOfVNA.Cost, 0) = 0
	|
	|			THEN 0
	|
	|		WHEN DocumentData.RevaluateAtFairValue
	|
	|			THEN DocumentTable.CostInManagementAccounting
	|
	|		ELSE DocumentTable.CostInManagementAccounting 
	|				- CAST(DocumentTable.CostInManagementAccounting 
	|							* (CAST(ISNULL(DepreciationOfVNA.Depreciation, 0) AS NUMBER (31,10))
	|								/ CAST(ISNULL(CostOfVNA.Cost, 0) AS NUMBER (31,10))) AS NUMBER (31,2))
	|				- CAST(DocumentTable.CostInManagementAccounting 
	|							* (CAST(ISNULL(ImpairmentFA.ImpairmenMan, 0) AS NUMBER (31,10))
	|								/ CAST(ISNULL(CostOfVNA.Cost, 0) AS NUMBER (31,10))) AS NUMBER (31,2))
	|
	|	END AS CostInManagementAccounting,
	|
	|	CASE
	|		WHEN NOT DocumentData.RecordInLocalAccounting
	|				OR (ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0)) = 0
	|
	|			THEN 0
	|
	|		WHEN DocumentData.RevaluateAtFairValue
	|
	|			THEN DocumentTable.CostInAccounting
	|
	|		ELSE DocumentTable.CostInAccounting 
	|				- CAST(DocumentTable.CostInAccounting 
	|							* (CAST(ISNULL(DepreciationOfVNA.DepreciationLocal, 0) + ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0) AS NUMBER (31,10))
	|								/ CAST(ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0) AS NUMBER (31,10))) AS NUMBER (31,2))
	|				- CAST(DocumentTable.CostInAccounting 
	|							* (CAST(ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) AS NUMBER (31,10))
	|								/ CAST(ISNULL(CostOfVNA.LocalCost, 0) + ISNULL(CostOfVNA.CostTargetFinancing, 0) AS NUMBER (31,10))) AS NUMBER (31,2))
	|
	|	END AS CostInAccounting	
	|
	|INTO TTFairCost
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentData_Table AS DocumentTable
	|		ON DocumentTable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentTable.Ref
	|			AND CostOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentTable.Ref
	|			AND DepreciationOfVNA.AccountingObject = &FixedAsset
	|
	|		LEFT JOIN TT_ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Ref = DocumentTable.Ref
	|			AND ImpairmentFA.AccountingObject = &FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|";
	
	ReplaceQueryTextParametersWhenReevaluating(QueryText, KindOfAccountingObjects, DocumentName);

	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTReflectionOfIncomeExpensesImpairment(QueryTexts)

	TableName = "TTReflectionOfIncomeExpensesImpairment";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	TTRecoveryOfImpairmentLoss.Ref AS Ref,
	|	TTRecoveryOfImpairmentLoss.Period AS Period,
	|	TTRecoveryOfImpairmentLoss.Organization AS Organization,
	|	TTRecoveryOfImpairmentLoss.AccountingObject AS AccountingObject,
	|	TTRecoveryOfImpairmentLoss.CGU AS CGU
	|
	|INTO TTListOfImpairmentObjects
	|
	|FROM
	|	TTRecoveryOfImpairmentLoss AS TTRecoveryOfImpairmentLoss
	|
	|INDEX BY
	|	Period,
	|	Organization
	|";
	QueryTexts.Add(QueryText, "TTListOfImpairmentObjects", False);
	
	QueryText =
	"SELECT
	|	RecentDocuments.Ref AS Ref,
	|	RecentDocuments.AccountingObject AS AccountingObject,
	|
	|	MAX(DocumentsList.ExpenseItem) AS ExpenseItem,
	|	MAX(DocumentsList.DimensionOfExpenses) AS DimensionOfExpenses,
	|	MAX(DocumentsList.IncomeItem) AS IncomeItem,
	|	MAX(DocumentsList.DimensionOfRevenue) AS DimensionOfRevenue
	|
	|INTO TTReflectionOfIncomeExpensesImpairment
	|
	|FROM
	|	(SELECT
	|		ImpairmentDocuments.Ref AS Ref,
	|		ImpairmentDocuments.Organization AS Organization,
	|		ImpairmentDocuments.AccountingObject AS AccountingObject,
	|		MAX(ImpairmentDocuments.Date) AS Date
	|	FROM
	|		(SELECT
	|			DocumentsList.Date AS Date,
	|			DocumentsList.Organization AS Organization,
	|			MainTable.Ref AS Ref,
	|			MainTable.AccountingObject AS AccountingObject
	|		FROM
	|			TTListOfImpairmentObjects AS MainTable
	|
	|				INNER JOIN Document.ImpairmentFA AS DocumentsList
	|				ON DocumentsList.Organization = MainTable.Organization
	|					AND DocumentsList.Date <= MainTable.Period
	|					AND DocumentsList.Posted
	|
	|				INNER JOIN Document.ImpairmentFA.CashGeneratingUnits AS DocumentTable
	|				ON DocumentTable.Ref = DocumentsList.Ref
	|					AND DocumentTable.CGU = MainTable.CGU
	|
	|		UNION ALL
	|
	|		SELECT
	|			DocumentsList.Date AS Date,
	|			DocumentsList.Organization AS Organization,
	|			MainTable.Ref AS Ref,
	|			MainTable.AccountingObject AS AccountingObject
	|		FROM
	|			TTListOfImpairmentObjects AS MainTable
	|
	|				INNER JOIN Document.ImpairmentFA AS DocumentsList
	|				ON DocumentsList.Organization = MainTable.Organization
	|					AND DocumentsList.Date <= MainTable.Period
	|					AND DocumentsList.Posted
	|
	|				INNER JOIN Document.ImpairmentFA.FixedAssets AS DocumentTable
	|				ON DocumentTable.Ref = DocumentsList.Ref
	|					AND DocumentTable.FixedAsset = MainTable.AccountingObject
	|
	|		UNION ALL
	|
	|		SELECT
	|			DocumentsList.Date AS Date,
	|			DocumentsList.Organization AS Organization,
	|			MainTable.Ref AS Ref,
	|			MainTable.AccountingObject AS AccountingObject
	|		FROM
	|			TTListOfImpairmentObjects AS MainTable
	|
	|				INNER JOIN Document.ImpairmentFA AS DocumentsList
	|				ON DocumentsList.Organization = MainTable.Organization
	|					AND DocumentsList.Date <= MainTable.Period
	|					AND DocumentsList.Posted
	|
	|				INNER JOIN Document.ImpairmentFA.IntangibleAssets AS DocumentTable
	|				ON DocumentTable.Ref = DocumentsList.Ref
	|					AND DocumentTable.IntangibleAsset = MainTable.AccountingObject
	|
	|		) AS ImpairmentDocuments
	|
	|	GROUP BY
	|		ImpairmentDocuments.Ref,
	|		ImpairmentDocuments.Organization,
	|		ImpairmentDocuments.AccountingObject) AS RecentDocuments
	|
	|		INNER JOIN Document.ImpairmentFA AS DocumentsList
	|		ON DocumentsList.Date = RecentDocuments.Date
	|			AND DocumentsList.Organization = RecentDocuments.Organization
	|			AND DocumentsList.Posted
	|
	|GROUP BY
	|	RecentDocuments.Ref,
	|	RecentDocuments.AccountingObject
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure ReplaceQueryTextParametersWhenReevaluating(QueryText, KindOfAccountingObjects, DocumentName)

	QueryText = StrReplace(QueryText, "Document.FARevaluation2_4.FA", DocumentName + "." + KindOfAccountingObjects);
	
	If KindOfAccountingObjects = "FA" Then 
		
		QueryText = StrReplace(QueryText, "DocumentData_Table", "DocumentDataFATable");
		
		QueryText = StrReplace(QueryText, "&FixedAsset", "DocumentTable.FixedAsset");
		QueryText = StrReplace(QueryText, "&Leaseholder", "FALocation.Leaseholder");
		
		QueryText = StrReplace(QueryText, "&CorrectionDate", "CorrectionDate = DATETIME(1,1,1)");
		
	Else
		
		QueryText = StrReplace(QueryText, "DocumentData_Table", "DocumentDataIATable");
		
		QueryText = StrReplace(QueryText, "&FixedAsset", "DocumentTable.IntangibleAsset");
		QueryText = StrReplace(QueryText, "AS FixedAsset", "AS IntangibleAsset");
		QueryText = StrReplace(QueryText, "TTAccountingFA", "TTAccountingProcedureForIA");
		QueryText = StrReplace(QueryText, "AccountingProcedure.FixedAsset", "AccountingProcedure.IntangibleAsset");
		QueryText = StrReplace(QueryText, "TTLocationOfFA", "TTIsEmptyTableFA");
		QueryText = StrReplace(QueryText, "&Leaseholder", "UNDEFINED");
		
		QueryText = StrReplace(QueryText, "&CorrectionDate", "");
		
	EndIf; 
	
EndProcedure

#EndRegion

#Region FinancialAccounting

Function SourcesOfAccountRefinementDepreciation(SourceProperties) Export
	
	SourcesOfInvoiceRefinement = New Map;
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfFixedAndIntangibleAssets,
		New Structure(SourceProperties, "HFCSNonCurrentAssets"));
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfIncomeExpenses,
		New Structure(SourceProperties, "HFCRevenueExpenditure"));
		
	Return SourcesOfInvoiceRefinement;
	
EndFunction

Function SourcesOfInvoiceRefinementCost(SourceProperties) Export
	
	SourcesOfInvoiceRefinement = New Map;
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfFixedAndIntangibleAssets,
		New Structure(SourceProperties, "HFCSNonCurrentAssets"));
		
	Return SourcesOfInvoiceRefinement;
	
EndFunction

Function SourcesOfDirections() Export

	Result = New Map;
	
	SourcesOfDirections = Enums.SourceOfLinesOfBusinessOfAnalyticalRegister;
	Result.Insert(SourcesOfDirections.LineOfBusiness, "LineOfBusiness");
	Result.Insert(SourcesOfDirections.CorLineOfBusiness, "CorLineOfBusiness");

	Return Result;
	
EndFunction

Function SourcesOfDivisionsDepreciation() Export

	SourcesOfDivisions = New Map;
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.BusinessOperation, "Department");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.Department, "Department");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.DebitBusinessUnit, "DebitBusinessUnit");
	
	Return SourcesOfDivisions;

EndFunction

Function SourcesAndCost() Export

	SourcesOfDivisions = New Map;
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.BusinessOperation, "Department");

	Return SourcesOfDivisions;

EndFunction

#EndRegion

#Region Posting

// Records movements from the movement table.
// 
// Parameters:
//  TablesForRegisteredRecords - Structure - Tables for movements.
//  Document - DocumentObject - Document.
//  TempTablesManager - TempTablesManager - temporary table manager.
//  ReturnDocumentsToReflection - Boolean -
//  OperationName - String - The operation in which the recording of movements is performed.
//  SourceKind - EnumRef.MovementSourcesKinds - Type of source.
//	Period - Date - The period of recording movements.
//	
// Returns:
//  Number - Number Of Processed Data
//
Function WriteMotionTables(TablesForRegisteredRecords, Document, TempTablesManager, ReturnDocumentsToReflection, OperationName = Undefined, SourceKind = Undefined, Period = Undefined) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("NonCurrentAssetsInternal.WriteMotionTables");

	ReplaceRecords = SourceKind = Undefined;
	
	DataVolume = 0;
	
	For Each KeyAndValue In TablesForRegisteredRecords Do
		
		RegisterName = NameOfRegisterByNameOfRegisteredRecordsTable(KeyAndValue.Key);
		
		RegisterTable = KeyAndValue.Value; // ValueTable
		If RegisterTable.Columns.Find("Recorder") <> Undefined Then
			DocumentEntries = RegisterTable.Copy(New Structure("Recorder", Document.Ref));
		Else
			DocumentEntries = RegisterTable;
		EndIf;
		
		If Upper(RegisterName) = Upper("ReflectionOfDocumentsInLocalAccounting") Then
			
			If ReturnDocumentsToReflection Then
			EndIf;
		ElsIf Upper(RegisterName) = Upper("DocumentPostingInFinancialAccounting") Then
			
			If ReturnDocumentsToReflection Then
				FinancialAccountingPostingServer.ReturnDocumentsToReflection(DocumentEntries);
			EndIf;
		Else
			If Metadata.InformationRegisters.Find(RegisterName) <> Undefined Then
				RecordSet = InformationRegisters[RegisterName].CreateRecordSet();
				LockSpace = "InformationRegister." + RegisterName + ".RecordSet";
			ElsIf Metadata.AccumulationRegisters.Find(RegisterName) <> Undefined Then
				RecordSet = AccumulationRegisters[RegisterName].CreateRecordSet();
				LockSpace = "AccumulationRegister." + RegisterName + ".RecordSet";
			Else
				Continue;
			EndIf;
			
			SeparateRecordsBySourceType = SourceKind <> Undefined 
					And RecordSet.Metadata().Attributes.Find("SourceKind") <> Undefined;
			
			Block = New DataLock;
			
			LockItem = Block.Add(LockSpace);
			LockItem.SetValue("Recorder", Document.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			RecordSet.Filter.Recorder.Set(Document.Ref);
			
			If SeparateRecordsBySourceType Then
				
				// Deleting records with the specified source type
				RecordSet.Read();
				For IndexOfRecord = -RecordSet.Count() + 1 To 0 Do
					RegisterRecord = RecordSet[-IndexOfRecord];
					If RegisterRecord.SourceKind = SourceKind
						And (Period = Undefined
							Or RegisterRecord.Period >= BegOfMonth(Period) 
								And RegisterRecord.Period <= EndOfMonth(Period)) Then
						RecordSet.Delete(-IndexOfRecord);
					EndIf;
					DataVolume = DataVolume + 1;
				EndDo;
				
				RecordSet.AdditionalProperties.Insert("CheckingDateWhenChangesWereBanned", False);
				
				SetPrivilegedMode(True);
				RecordSet.Write();
				SetPrivilegedMode(False);
				
				RecordSet.Clear();
				RecordSet.AdditionalProperties.Delete("CheckingDateWhenChangesWereBanned");
				
			EndIf;
			
			DocumentsPosting.SetAdditionalRegisterProperties(RecordSet, Document, TempTablesManager, True);
	
			If OperationName <> Undefined Then
				RecordSet.AdditionalProperties.Insert(OperationName, True);
			EndIf;
			
			For Each RowData In DocumentEntries Do
				
				RegisterRecord = RecordSet.Add();
				FillPropertyValues(RegisterRecord, RowData);
				
				If SeparateRecordsBySourceType Then
					RegisterRecord.SourceKind = SourceKind;
				EndIf;
				
				DataVolume = DataVolume + 1;
				
			EndDo;
			
			SetPrivilegedMode(True);
			RecordSet.Write(ReplaceRecords Or Not SeparateRecordsBySourceType);
			SetPrivilegedMode(False);
			
		EndIf;
		
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
	Return DataVolume;
	
EndFunction

// The register name is based on the Registered Records table name.
// 
// Parameters:
//  MotionTableName - String -  Motion Table Name
// 
// Returns:
//  String - Register name
Function NameOfRegisterByNameOfRegisteredRecordsTable(MotionTableName) Export
	
	TableServiceName = Upper("TABLE");
	LengthOfTableName = StrLen(TableServiceName);
	
	RegisterName = MotionTableName;
	If Upper(Left(RegisterName, LengthOfTableName)) = TableServiceName Then
		RegisterName = Right(RegisterName, StrLen(RegisterName) - LengthOfTableName);
	EndIf;
	
	Return RegisterName;
	
EndFunction

// Replaces additional fields in the request.
// 
// Parameters:
//  QueryText - String - Query text
//  AdditionalFields - String - Additional request fields
//  Exceptions - String - Query fields that don't need to be replaced
Procedure ReplaceAdditionalFieldsInRequest(QueryText, AdditionalFields, Exceptions = "") Export
	
	If ValueIsFilled(AdditionalFields) Then
		
		TextAdditionalFields = "";
		
		FieldList = StrSplit(AdditionalFields, ",");
		ExceptionsList = StrSplit(Exceptions, ",");
		For Each FieldName In FieldList Do
			If ExceptionsList.Find(FieldName) = Undefined Then
				TextAdditionalFields = TextAdditionalFields + "
				|	, 0 AS " + FieldName;
			EndIf;
		EndDo; 
		
		QueryText = StrReplace(QueryText, ",&AdditionalFields", TextAdditionalFields); 
		
	Else
		QueryText = StrReplace(QueryText, ",&AdditionalFields", "");
	EndIf; 
	
EndProcedure

Procedure ReflectInManagementBalanceSheet(MovementTables, TempTablesManager) Export

	If Not GetFunctionalOption("UseBalanceSheetStatement") Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		// With the new architecture of the AR/AP accounting, tasks of the non-operational queue should be generated.
		Return;
	EndIf;
		
	BalanceManTables = New Structure;
	For Each Table In MovementTables Do
		For Each Item In Table.Value Do
			BalanceManTables.Insert(Item.Key);
		EndDo;
	EndDo;
		
	QueryText = 
	"SELECT DISTINCT
	|	TTPortionOfDataToBeCalculated.Ref AS Ref
	|FROM
	|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	DocumentsToBeReflected = New Array;
	RecordingOfDocument = New Map;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		DocumentType = TypeOf(Selection.Ref);
		DocumentReflectedInManSBalanceSheet = RecordingOfDocument.Get(DocumentType);
		If DocumentReflectedInManSBalanceSheet = Undefined Then
			MetadataOfDocument = Selection.Ref.Metadata();
			DocumentReflectedInManSBalanceSheet = MetadataOfDocument.RegisterRecords.Contains(Metadata.AccumulationRegisters.OtherAssetsLiabilities);
			RecordingOfDocument.Insert(DocumentType, DocumentReflectedInManSBalanceSheet);
		EndIf;
		
		If DocumentReflectedInManSBalanceSheet Then
			DocumentsToBeReflected.Add(Selection.Ref);
		EndIf;
		
	EndDo;
	
	DataProcessors.FlowOfAssetsAndLiabilities.ReflectDocumentsInManagementBalanceSheet(DocumentsToBeReflected, BalanceManTables);
	
EndProcedure

// 
// Parameters:
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4, DocumentObject.FixedAssetsCostAdditions2_4, DocumentObject.RecognizeSubAssetsComponentsOfDepreciation - Document
//  Cancel - Boolean - Cancel
Procedure CheckFACostGenerationProcedure(Object, Cancel) Export
	
	If TypeOf(Object) = Type("DocumentObject.FixedAssetsInitialRecognition2_4") Then
		PostInAccounting = Object.PostInAccounting;
		RecordInTA = Object.RecordInTA;
		RecordInMA = Object.RecordInManAccounting;
	Else
		PostInAccounting = Object.RecordInLocalAccounting;
		RecordInTA = Object.RecordInLocalAccounting;
		RecordInMA = Object.RecordInManAccounting;
	EndIf;
	
	If TypeOf(Object) = Type("DocumentObject.RecognizeSubAssetsComponentsOfDepreciation") Then
		PathToTabularSection = "DepreciationComponents";
		ListOfFA = Object.DepreciationComponents.UnloadColumn("DepreciationComponent");
	Else
		PathToTabularSection = "FA";
		ListOfFA = Object.FA.UnloadColumn("FixedAsset");
	EndIf;
	
	If ListOfFA.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	FATable.Ref AS Ref,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.FixedAsset.Presentation AS FixedAssetPresentation
	|
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DocumentData
	|
	|		INNER JOIN Document.FixedAssetsInitialRecognition2_4.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.Ref <> &Ref
	|	AND DocumentData.Posted
	|
	|	AND (&PostInAccounting
	|			AND DocumentData.PostInAccounting
	|		OR &RecordInTA
	|			AND DocumentData.RecordInTA
	|		OR &RecordInMA
	|			AND DocumentData.RecordInManAccounting)
	|
	|	AND FATable.FixedAsset IN (&ListOfFA)
	|
	|	AND (&CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost)
	|		OR DocumentData.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost))
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	FATable.Ref AS Ref,
	|	FATable.DepreciationComponent AS FixedAsset,
	|	FATable.DepreciationComponent.Presentation AS FixedAssetPresentation
	|
	|FROM
	|	Document.RecognizeSubAssetsComponentsOfDepreciation AS DocumentData
	|
	|		INNER JOIN Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.Ref <> &Ref
	|	AND DocumentData.Posted
	|
	|	AND (&PostInAccounting
	|			AND DocumentData.RecordInLocalAccounting
	|		OR &RecordInMA
	|			AND DocumentData.RecordInManAccounting)
	|
	|	AND FATable.DepreciationComponent IN (&ListOfFA)
	|
	|	AND (&CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost)
	|		OR DocumentData.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost))
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	FATable.Ref AS Ref,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.FixedAsset.Presentation AS FixedAssetPresentation
	|
	|FROM
	|	Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|
	|		INNER JOIN Document.FixedAssetsCostAdditions2_4.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.Ref <> &Ref
	|	AND DocumentData.Posted
	|
	|	AND (&PostInAccounting
	|			AND DocumentData.RecordInLocalAccounting
	|		OR &RecordInTA
	|			AND DocumentData.RecordInLocalAccounting
	|		OR &RecordInMA
	|			AND DocumentData.RecordInManAccounting)
	|
	|	AND FATable.FixedAsset IN (&ListOfFA)
	|
	|	AND (&CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost)
	|		OR DocumentData.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost))
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("BegOfMonth", ?(Object.Date <> '00010101', BegOfMonth(Object.Date), BegOfMonth(CurrentSessionDate())));
	Query.SetParameter("EndOfMonth", ?(Object.Date <> '00010101', EndOfMonth(Object.Date), EndOfMonth(CurrentSessionDate())));
	Query.SetParameter("CostGenerationProcedure", Object.CostGenerationProcedure);
	Query.SetParameter("ListOfFA", ListOfFA);
	Query.SetParameter("PostInAccounting", PostInAccounting);
	Query.SetParameter("RecordInTA", RecordInTA);
	Query.SetParameter("RecordInMA", RecordInMA);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	MessageText = NStr("vi = 'Với phương thức hình thành giá trị ""Bao gồm chi phí phát sinh trước cuối tháng lập chứng từ"", chỉ được phép lập một chứng từ trong cùng tháng (đối với tài sản cố định %1 đã lập chứng từ %2)';
						|ru = 'При порядке формирования стоимости ""Включить в стоимость расходы, поступившие до конца месяца, в котором оформлен документ"" допускается оформление только одного документа в том же месяце (для основного средства %1 уже оформлен документ %2)';
						|en = 'If the ""Include expenses received before end of month in which document is created"" cost generation procedure is used, only one document can be issued in the same month (for the %1 fixed asset, the %2 document is already issued)'; fa = 'If the ""Include expenses received before end of month in which document is created"" cost generation procedure is used, only one document can be issued in the same month (for the %1 fixed asset, the %2 document is already issued)';
						|it = 'If the ""Include expenses received before end of month in which document is created"" cost generation procedure is used, only one document can be issued in the same month (for the %1 fixed asset, the %2 document is already issued)';
						|pl = 'If the ""Include expenses received before end of month in which document is created"" cost generation procedure is used, only one document can be issued in the same month (for the %1 fixed asset, the %2 document is already issued)';
						|tr = '""Belgenin oluşturulduğu ayın sonuna kadar gelen giderleri maliyete dahil et"" maliyet oluşturma düzeninde, aynı ay içinde sadece tek bir belgenin oluşturulmasına izin verilir (%1 sabit kıymeti için %2 belgesi zaten oluşturulmuş)'");
	MessageText = StrTemplate(MessageText, Selection.FixedAssetPresentation, String(Selection.Ref));
	
	If TypeOf(Object) = Type("DocumentObject.RecognizeSubAssetsComponentsOfDepreciation") Then
		RowData = Object.DepreciationComponents.Find(Selection.FixedAsset, "DepreciationComponent");
		Field = CommonClientServer.PathToTabularSection(PathToTabularSection, RowData.LineNumber, "DepreciationComponent");
	Else
		RowData = Object.FA.Find(Selection.FixedAsset, "FixedAsset");
		Field = CommonClientServer.PathToTabularSection(PathToTabularSection, RowData.LineNumber, "FixedAsset");
	EndIf;

	Common.MessageToUser(MessageText, Object, Field, "", Cancel);
	
EndProcedure

// 
// Parameters:
//  Object - DocumentObject.IntangibleAssetsInitialRecognition2_4, DocumentObject.IntangibleAssetImprovement - Document
//  Cancel - Boolean - Cancel
Procedure CheckProcedureForGeneratingIACost(Object, Cancel) Export
	
	PostInAccounting = Object.PostInAccounting;
	RecordInTA = Object.RecordInTA;
	RecordInMA = Object.RecordInManAccounting;
	
	If TypeOf(Object) = Type("DocumentObject.IntangibleAssetsInitialRecognition2_4") Then
		ListOfIA = CommonClientServer.ValueInArray(Object.IntangibleAsset);
	Else
		ListOfIA = Object.IA.UnloadColumn("IntangibleAsset");
	EndIf;
	
	If ListOfIA.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	DocumentData.Ref AS Ref,
	|	DocumentData.IntangibleAsset AS IntangibleAsset,
	|	DocumentData.IntangibleAsset.Presentation AS IntangibleAssetPresentation
	|
	|FROM
	|	Document.IntangibleAssetsInitialRecognition2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.Ref <> &Ref
	|	AND DocumentData.Posted
	|
	|	AND (&PostInAccounting
	|			AND DocumentData.PostInAccounting
	|		OR &RecordInTA
	|			AND DocumentData.RecordInTA
	|		OR &RecordInMA
	|			AND DocumentData.RecordInManAccounting)
	|
	|	AND DocumentData.IntangibleAsset IN (&ListOfIA)
	|
	|	AND (&CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost)
	|		OR DocumentData.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost))
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TableOfIA.Ref AS Ref,
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|	TableOfIA.IntangibleAsset.Presentation AS IntangibleAssetPresentation
	|
	|FROM
	|	Document.IntangibleAssetImprovement AS DocumentData
	|
	|		INNER JOIN Document.IntangibleAssetImprovement.IA AS TableOfIA
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DocumentData.Ref <> &Ref
	|	AND DocumentData.Posted
	|
	|	AND (&PostInAccounting
	|			AND DocumentData.PostInAccounting
	|		OR &RecordInTA
	|			AND DocumentData.RecordInTA
	|		OR &RecordInMA
	|			AND DocumentData.RecordInManAccounting)
	|
	|	AND TableOfIA.IntangibleAsset IN (&ListOfIA)
	|
	|	AND (&CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost)
	|		OR DocumentData.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost))
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("BegOfMonth", ?(Object.Date <> '00010101', BegOfMonth(Object.Date), BegOfMonth(CurrentSessionDate())));
	Query.SetParameter("EndOfMonth", ?(Object.Date <> '00010101', EndOfMonth(Object.Date), EndOfMonth(CurrentSessionDate())));
	Query.SetParameter("CostGenerationProcedure", Object.CostGenerationProcedure);
	Query.SetParameter("ListOfIA", ListOfIA);
	Query.SetParameter("PostInAccounting", PostInAccounting);
	Query.SetParameter("RecordInTA", RecordInTA);
	Query.SetParameter("RecordInMA", RecordInMA);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	MessageText = NStr("vi = 'Với phương thức hình thành giá trị ""Bao gồm chi phí phát sinh trước cuối tháng lập chứng từ"", chỉ được phép lập một chứng từ trong cùng tháng (đối với tài sản cố định vô hình %1 đã lập chứng từ %2)';
						|ru = 'При порядке формирования стоимости ""Включить в стоимость расходы, поступившие до конца месяца, в котором оформлен документ"" допускается оформление только одного документа в том же месяце (для нематериального актива %1 уже оформлен документ %2)';
						|en = 'If the ""Include expenses received before end of month in which document is created"" cost generation procedure is used, only one document can be issued in the same month (for the %1 intangible asset, the %2 document is already issued)'; fa = 'If the ""Include expenses received before end of month in which document is created"" cost generation procedure is used, only one document can be issued in the same month (for the %1 intangible asset, the %2 document is already issued)';
						|it = 'If the ""Include expenses received before end of month in which document is created"" cost generation procedure is used, only one document can be issued in the same month (for the %1 intangible asset, the %2 document is already issued)';
						|pl = 'If the ""Include expenses received before end of month in which document is created"" cost generation procedure is used, only one document can be issued in the same month (for the %1 intangible asset, the %2 document is already issued)';
						|tr = '""Belgenin oluşturulduğu ayın sonuna kadar gelen giderleri maliyete dahil et"" maliyet oluşturma düzeninde, aynı ay içinde sadece tek bir belgenin oluşturulmasına izin verilir (%1 maddi olmayan varlığı için %2 belgesi zaten oluşturulmuş)'");
	MessageText = StrTemplate(MessageText, Selection.IntangibleAssetPresentation, String(Selection.Ref));
	
	If TypeOf(Object) = Type("DocumentObject.IntangibleAssetsInitialRecognition2_4") Then
		Common.MessageToUser(MessageText, Object, "IntangibleAsset", "", Cancel);
	Else
		RowData = Object.IA.Find(Selection.IntangibleAsset, "IntangibleAsset");
		Field = CommonClientServer.PathToTabularSection("IA", RowData.LineNumber, "IntangibleAsset");
		Common.MessageToUser(MessageText, Object, Field, "", Cancel);
	EndIf;
	
EndProcedure

// 
// Parameters:
//  QueryTexts - ValueList - Request texts
//  Registers - Structure - a list of register names for which you want to table
Procedure QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers) Export
	
	RegisterName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.Ref AS Document,
	|	DocumentData.Organization AS Organization,
	|	BEGINOFPERIOD(DocumentData.Period, DAY) AS DateRecord,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData";

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

#EndRegion

#Region Other

Procedure ReturnDocumentsToReflection(Ref, Organization, Date, TablesForRegisteredRecords) Export
	
	NonCurrentAssetsLocalization.ReturnDocumentsToReflection(Ref, Organization, Date, TablesForRegisteredRecords);
	If Ref.Metadata().RegisterRecords.Contains(Metadata.InformationRegisters.DocumentPostingInFinancialAccounting) Then
		
		TableNameReflectionOfDocumentsInInternationalAccounting = "Table" + "DocumentPostingInFinancialAccounting";
		
		If TablesForRegisteredRecords.Property(TableNameReflectionOfDocumentsInInternationalAccounting) Then
			TableReflectionOfDocumentsInAccounting = TablesForRegisteredRecords[TableNameReflectionOfDocumentsInInternationalAccounting];
		ElsIf TablesForRegisteredRecords.Property("DocumentPostingInFinancialAccounting") Then
			TableReflectionOfDocumentsInAccounting = TablesForRegisteredRecords.DocumentPostingInFinancialAccounting;
		Else
			TableReflectionOfDocumentsInAccounting = DocumentReflectionTable(Ref, Organization, Date);
		EndIf;
		
		FinancialAccountingPostingServer.ReturnDocumentsToReflection(TableReflectionOfDocumentsInAccounting);

	EndIf;
EndProcedure

Procedure UpdateRegisteredRecordsOfAssetsLiabilities(Ref) Export

	MetadataOfDocument = Ref.Metadata();
	If Not MetadataOfDocument.RegisterRecords.Contains(Metadata.AccumulationRegisters.OtherAssetsLiabilities) Then
		Return;
	EndIf;

	ListOfDocumentRegisters = New Array;

	BalanceRegisters = DataProcessors.FlowOfAssetsAndLiabilities.BalanceRegisters();
	For Each Source In BalanceRegisters Do
		If Upper(Source.Key) <> Upper("OtherAssetsLiabilities")
			And MetadataOfDocument.RegisterRecords.Contains(Metadata.AccumulationRegisters[Source.Key]) Then
			ListOfDocumentRegisters.Add(Source.Key);
		EndIf;
	EndDo;
	
	Block = New DataLock;
	
	LockItem = Block.Add("AccumulationRegister.OtherAssetsLiabilities.RecordSet");
	LockItem.SetValue("Recorder", Ref);
	LockItem.Mode = DataLockMode.Exclusive;
	
	For Each RegisterName In ListOfDocumentRegisters Do
		LockItem = Block.Add("AccumulationRegister." + RegisterName + ".RecordSet");
		LockItem.SetValue("Recorder", Ref);
		LockItem.Mode = DataLockMode.Shared;
	EndDo;
	
	Block.Lock();
	
	BalanceManRegisteredRecords = New Structure;

	OtherAssetsLiabilities = AccumulationRegisters.OtherAssetsLiabilities.CreateRecordSet();
	OtherAssetsLiabilities.Filter.Recorder.Set(Ref);
	OtherAssetsLiabilities.Read();
	BalanceManRegisteredRecords.Insert("OtherAssetsLiabilities", OtherAssetsLiabilities.Unload());
	
	For Each RegisterName In ListOfDocumentRegisters Do
		RegisterRecords = AccumulationRegisters[RegisterName].CreateRecordSet();
		RegisterRecords.Filter.Recorder.Set(Ref);
		RegisterRecords.Read();
		BalanceManRegisteredRecords.Insert(RegisterName, RegisterRecords.Unload());
	EndDo;
	
	ManagementAccountingPostingServer.UpdateRegisteredRecordsOfAssetsLiabilities(Ref, BalanceManRegisteredRecords);
	
	OtherAssetsLiabilities.Load(BalanceManRegisteredRecords.OtherAssetsLiabilities);
	
	OtherAssetsLiabilities.Write();
	
EndProcedure

Function DocumentReflectionTable(DocumentRef, Organization, DateRecord) Export

	DocumentReflectionTable = New ValueTable;
	DocumentReflectionTable.Columns.Add("Document", New TypeDescription(CommonClientServer.ValueInArray(TypeOf(DocumentRef))));
	DocumentReflectionTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	DocumentReflectionTable.Columns.Add("DateRecord", New TypeDescription("Date"));
	DocumentReflectionTable.Columns.Add("Period", New TypeDescription("Date"));
	
	NewRow = DocumentReflectionTable.Add();
	NewRow.Document = DocumentRef;
	NewRow.Organization = Organization;
	NewRow.DateRecord = BegOfDay(DateRecord);
	NewRow.Period = BegOfDay(DateRecord);

	Return DocumentReflectionTable;
	
EndFunction

Procedure AddSelectionText(TextSelections, ConditionText) Export
	
	If Not IsBlankString(ConditionText) Then
		
		TextAnd = "AND"; // @query-part-1
		
		TextSelections = TextSelections + "
			|	" + ?(TextSelections <> "",  TextAnd + " (","(") + ConditionText + ")
			|";
			
	EndIf;
	
EndProcedure

Function TitleOfCaptionAboutDocumentInAnotherAccount(DocumentAttributes)

	LabelTitle = New Array;
	If DocumentAttributes.DeletionMark 
		Or DocumentAttributes.RecordInManAccounting 
			And DocumentAttributes.RecordInLocalAccounting Then						
		// A hyperlink about documents in another accounting is not displayed if another document is reflected in both accounts.
		Return LabelTitle;
	EndIf; 
	
	MetadataOfDocument = DocumentAttributes.Ref.Metadata();
	PresentationOfDocument = PresentationOfDocument(MetadataOfDocument.Synonym);
	TextAcceptedByMa = StrTemplate(NStr("vi = 'Trong kế toán quản trị đã tạo chứng từ %1';
										|ru = 'В управленческом учете создан документ %1';
										|en = 'The %1 document is created in management accounting'; fa = 'The %1 document is created in management accounting';
										|it = 'Documento creato nella contabilità gestionale %1';
										|pl = 'W ewidencji zarządzczej został utworzony dokument %1';
										|tr = 'Yönetim muhasebesinde bir %1belge oluşturuldu'"), PresentationOfDocument);
	TextAcceptedByAC = StrTemplate(NStr("vi = 'Trong kế toán tài chính, đã tạo mới chứng từ %1';
										|ru = 'В регламентированном учете создан документ %1';
										|en = 'The %1 document is created in local accounting'; fa = 'The %1 document is created in local accounting';
										|it = 'Documento creato nella contabilità regolatoria %1';
										|pl = 'W ewidencji reglamentowanej nie został utworzony dokument %1';
										|tr = 'Yerel muhasebede bir %1belge oluşturuldu'"), PresentationOfDocument);
		
	If DocumentAttributes.RecordInManAccounting Then
		LabelTitle.Add(TextAcceptedByMa);
	Else
		LabelTitle.Add(TextAcceptedByAC);
	EndIf;
	LabelTitle.Add(" ");
	
	OrderPresentation = StrTemplate(NStr("vi = 'Số%1 ngày %2';
										|ru = '№%1 от %2';
										|en = 'No. %1 from %2'; fa = 'No. %1 from %2';
										|it = '№%1 da %2';
										|pl = 'Nr%1 z dnia %2';
										|tr = 'no %1 tarih %2'"), 
								ObjectsPrefixesClientServer.NumberForPrinting(
										DocumentAttributes.Number, False, True),
								Format(DocumentAttributes.Date, "DLF=D"));
	
	LabelTitle.Add(New FormattedString(OrderPresentation,,,, GetURL(DocumentAttributes.Ref)));
	
	If Not DocumentAttributes.Posted Then
		LabelTitle.Add(" ");
		LabelTitle.Add(New FormattedString(
									NStr("vi = 'không được thực hiện';
										|ru = 'не проведен';
										|en = 'not posted'; fa = 'not posted';
										|it = 'Non effettuato';
										|pl = 'nie zaksięgowany';
										|tr = 'gerçekleştirilmedi'"),, StyleColors.SpecialTextColor));
	EndIf;
		
	Return LabelTitle;
	
EndFunction

Function FindDocumentInAnotherAccountAndGenerateTitle(Object, ShowInformationIfNotCreated)
	
	LabelTitle = New Array;
	
	If Not ValueIsFilled(Object.Ref) Then
		Return LabelTitle;
	EndIf;
	
	MetadataOfDocument = Object.Ref.Metadata();
	DocumentName = MetadataOfDocument.Name;
	
	PresentationOfDocument = PresentationOfDocument(MetadataOfDocument.Synonym);
	TextNotAcceptedByMa = StrTemplate(NStr("vi = 'Trong kế toán quản trị chưa tạo chứng từ %1';
											|ru = 'В управленческом учете не создан документ %1';
											|en = 'The %1 document is not created in management accounting'; fa = 'The %1 document is not created in management accounting';
											|it = 'Documento non creato nella contabilità gestionale %1';
											|pl = 'W ewidencji zarządzczej nie został utworzony dokument %1';
											|tr = 'Yönetim muhasebesinde bir %1belge oluşturulmamıştır'"), PresentationOfDocument);
	TextNotAcceptedByAC = StrTemplate(NStr("vi = 'Trong kế toán tài chính chưa tạo mới chứng từ %1';
											|ru = 'В регламентированном учете не создан документ %1';
											|en = 'The %1 document is not created in local accounting'; fa = 'The %1 document is not created in local accounting';
											|it = 'Documento non creato nella contabilità regolatoria %1';
											|pl = 'W ewidencji reglamentowanej nie został utworzony dokument %1';
											|tr = 'Düzenlenmiş muhasebede bir %1belge oluşturulmamıştır'"), PresentationOfDocument);
	FormatText_ = NStr("vi = 'Tạo mới';
						|ru = 'Создать';
						|en = 'Create'; fa = 'ایجاد';
						|it = 'Creare';
						|pl = 'Utwórz';
						|tr = 'Oluştur'");
	
	QueryText = 
	"SELECT ALLOWED TOP 1
	|	1 AS Priority,
	|	DocumentData.Ref,
	|	DocumentData.Number,
	|	DocumentData.Date,
	|	DocumentData.DeletionMark,
	|	DocumentData.Posted,
	|	DocumentData.RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting
	|FROM
	|	DocumentName AS DocumentData
	|WHERE
	|	DocumentData.DocumentInAnotherAccounting = &Ref
	|	AND DocumentData.Posted
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	2,
	|	DocumentData.Ref,
	|	DocumentData.Number,
	|	DocumentData.Date,
	|	DocumentData.DeletionMark,
	|	DocumentData.Posted,
	|	DocumentData.RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting
	|FROM
	|	DocumentName AS DocumentData
	|WHERE
	|	DocumentData.DocumentInAnotherAccounting = &Ref
	|	AND NOT DocumentData.Posted
	|	AND NOT DocumentData.DeletionMark
	|
	|ORDER BY
	|	Priority";
	
	QueryText = StrReplace(QueryText, "DocumentName", "Document." + DocumentName);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		
		LabelTitle = TitleOfCaptionAboutDocumentInAnotherAccount(Selection);
		
	ElsIf (Not Object.RecordInManAccounting Or Not Object.RecordInLocalAccounting) And ShowInformationIfNotCreated Then
		
		If Not Object.RecordInManAccounting Then
			LabelTitle.Add(TextNotAcceptedByMa);
		Else
			LabelTitle.Add(TextNotAcceptedByAC);
		EndIf;
		
		If AccessRight("InteractiveInsert", Metadata.Documents[DocumentName]) Then
			LabelTitle.Add(" ");
			LabelTitle.Add(New FormattedString(FormatText_,,,, "#CreateDocument"));
		EndIf;
		
	EndIf;
	
	Return LabelTitle;

EndFunction

Function PresentationOfDocument(DocumentSynonym)

	PresentationOfDocument = DocumentSynonym;
	
	If StrEndsWith(DocumentSynonym, NStr("vi = 'TSCĐ';
										|ru = 'ОС';
										|en = 'Fixed assets'; fa = 'دارایی‌های ثابت';
										|it = 'Capitali fissi';
										|pl = 'Fixed assets';
										|tr = 'SV'")) Then
		PresentationOfDocument = TrimAll(Left(DocumentSynonym, StrLen(DocumentSynonym) - 2));
	ElsIf StrEndsWith(DocumentSynonym, NStr("vi = 'TSCĐ vô hình';
											|ru = 'НМА';
											|en = 'Intangible assets'; fa = 'دارایی‌های نامشهود';
											|it = 'Attivi immateriali';
											|pl = 'Intangible assets';
											|tr = 'GMA'")) Then
		PresentationOfDocument = TrimAll(Left(DocumentSynonym, StrLen(DocumentSynonym) - 3));
	EndIf; 

	Return PresentationOfDocument;
	
EndFunction

Procedure MessageToUser(MessageText, Object, MainToolInHeader, Path, Cancel)
	
	If MainToolInHeader Then
		Common.MessageToUser(MessageText, Object, "FixedAsset",, Cancel);
	Else
		Common.MessageToUser(MessageText, Object, Path,, Cancel);
	EndIf;

EndProcedure

// 
// Parameters:
//  RegisterName - String - Register name
// 
// Returns:
//  Boolean - 
Function RegisterSupportsCorrection(RegisterName) Export
	
	RegistersList = New Array;
	RegistersList.Add(Upper("FALocation"));
	RegistersList.Add(Upper("OSBUDepreciationParameters"));
	RegistersList.Add(Upper("FixedAssetDepreciationParametersManagementAccounting"));
	RegistersList.Add(Upper("InitialFixedAssetsInformation"));
	RegistersList.Add(Upper("FixedAssetsAccountingProcedure"));
	RegistersList.Add(Upper("AccountingProcedureForOSBU"));
	RegistersList.Add(Upper("FixedAssetsAccountingProcedureManagementAccounting"));

	NonCurrentAssetsLocalization.AddRegistersThatSupportCorrections(RegistersList);
		
	Return RegistersList.Find(Upper(RegisterName)) <> Undefined;
	
EndFunction

Procedure CheckHandlerExecution(ObjectsWithIssuesCount, ObjectsProcessed, FullObjectName) Export

 	If ObjectsWithIssuesCount <> 0 And ObjectsProcessed = 0 Then
		MessageText = 
			StrTemplate(NStr("vi = 'Không thể thực hiện hàm sự kiện cập nhật đối tượng metadata ""%1"".
						   |Chi tiết xem trong nhật ký sự kiện.';
						   |ru = 'Не удалось выполнить обработчик обновления объекта метаданных ""%1"".
						   |Подробности в журнале регистрации.';
						   |en = 'The metadata object update handler ""%1"" failed.
						   |Details in the event log.'; fa = 'The metadata object update handler ""%1"" failed.
						   |Details in the event log.';
						   |it = 'Non è stato possibile eseguire il gestore di aggiornamenti dell''oggetto metadati ""%1"".
						   | Ulteriori dettagli nel registro.';
						   |pl = 'Nie udało się wykonać procedury aktualizacji obiektu metadanych""%1"".
						   |Szczegóły są w dzienniku rejestracji.';
						   |tr = 'Meta veri nesnesi güncelleştirme işleyicisi ''%1'' başarısız oldu. 
						   |Ayrıntılar kayıt defterinde.'"),
						FullObjectName);
 		
		Raise MessageText;
 	EndIf;
	
EndProcedure

// 
// Parameters:
//  InformationAboutAccounting - Structure - Accounting Information
//  PresentationOfInformation - Structure - Presentation Of Information
Procedure PresentationOfInformationOnDateOfAcceptanceForAccounting(InformationAboutAccounting, PresentationOfInformation) Export
	
	If InformationAboutAccounting = Undefined Then
		PresentationOfInformation.Insert("InformationAcceptedForAccounting1", Undefined);
		PresentationOfInformation.Insert("InformationAcceptedForAccounting2", Undefined);
		PresentationOfInformation.Insert("InformationAcceptedForAccounting3", Undefined);
		Return;	
	EndIf;
	
	InformationParameters = InformationParameters();
	InformationParameters.NameOfInformationRecords = "InformationAcceptedForAccounting";
	InformationParameters.Value1 = InformationAboutAccounting.CommissioningDateAC;
	InformationParameters.Value2 = InformationAboutAccounting.CommissioningDateTA;
	InformationParameters.Value3 = InformationAboutAccounting.CommissioningDateMA;
	InformationParameters.Document1 = InformationAboutAccounting.CommissioningDocumentAC;
	InformationParameters.Document2 = InformationAboutAccounting.CommissioningDocumentTA;
	InformationParameters.Document3 = InformationAboutAccounting.CommissioningDocumentMA;

	If InformationAboutAccounting <> Undefined
		And (InformationAboutAccounting.BUState = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting
			Or InformationAboutAccounting.StateOfTheUU = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting) Then
				
		InformationParameters.Title = NStr("vi = 'Ngày tiếp nhận vào kế toán ngoại bảng:';
											|ru = 'Дата принятия к забалансовому учету:';
											|en = 'Date of entering in off-balance accounting:'; fa = 'Date of entering in off-balance accounting:';
											|it = 'Data di accettazione nella contabilità fuori bilancio:';
											|pl = 'Data przyjęcia do ewidencji pozabilansowej:';
											|tr = 'Bilanço dışı muhasebe için kabul tarihi:'");
	Else
		InformationParameters.Title = NStr("vi = 'Ngày bắt đầu hạch toán:';
											|ru = 'Дата принятия к учету:';
											|en = 'Date of recognition:'; fa = 'Date of recognition:';
											|it = 'Data di accettazione nella contabilità:';
											|pl = 'Data przyjęcia do ewidencji:';
											|tr = 'Muhasebeleştirme tarihi'");
		InformationParameters.Title1 = NStr("vi = 'Ngày tiếp nhận vào kế toán doanh nghiệp:';
											|ru = 'Дата принятия в бух. учете:';
											|en = 'Date of recognition in local accounting:'; fa = 'Date of recognition in local accounting:';
											|it = 'Data di accettazione nella contabilità ordinaria:';
											|pl = 'Data przyjęcia w ewidencji księgowej:';
											|tr = 'Genel muhasebeye kabul tarihi:'");
		InformationParameters.Title2 = NStr("vi = 'Ngày tiếp nhận vào kế toán thuế:';
											|ru = 'Дата принятия в нал. учете:';
											|en = 'Date of recognition in tax accounting:'; fa = 'Date of recognition in tax accounting:';
											|it = 'Data di accettazione nella contabilità fiscale:';
											|pl = 'Data przyjęcia w ewidencji podatkowej:';
											|tr = 'Vergi muhasebesine kabul tarihi:'");
		InformationParameters.Title3 = NStr("vi = 'Ngày tiếp nhận vào kế toán:';
											|ru = 'Дата принятия в упр. учете:';
											|en = 'Date of recognition in mgmt accounting:'; fa = 'Date of recognition in mgmt accounting:';
											|it = 'Data di accettazione nella contabilità gestionale:';
											|pl = 'Data przyjęcia w ewidencji zarz.:';
											|tr = 'Yönetim muhasebesine kabul tarihi:'");
	EndIf;

	InformationParameters.Action1 = New FormattedString(NStr("vi = 'Cần tiếp nhận vào kế toán';
															|ru = 'Принять к учету';
															|en = 'Recognize'; fa = 'شناسایی';
															|it = 'Принять к учету';
															|pl = 'Recognize';
															|tr = 'Kitaplara gir'"),,,, "#Create");
	
	PresentationOfInformation(InformationParameters, InformationAboutAccounting, PresentationOfInformation);
	
EndProcedure

// 
// Parameters:
//  InformationAboutAccounting - Structure - 
//  PresentationOfInformation - Structure -
Procedure PresentationOfInformationAboutPeriodOfUse(InformationAboutAccounting, PresentationOfInformation) Export
	
	If InformationAboutAccounting = Undefined Then
		PresentationOfInformation.Insert("InformationTermOfUse1", Undefined);
		PresentationOfInformation.Insert("InformationTermOfUse2", Undefined);
		PresentationOfInformation.Insert("InformationTermOfUse3", Undefined);
		Return;	
	EndIf;

	InformationParameters = InformationParameters();
	InformationParameters.NameOfInformationRecords = "InformationTermOfUse";
	InformationParameters.Value1 = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(InformationAboutAccounting.UsefulLifeAccounting, False);
	InformationParameters.Value2 = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(InformationAboutAccounting.UsefulLifeTaxAccounting, False);
	InformationParameters.Value3 = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(InformationAboutAccounting.UsefulLifeManagementAccounting, False);
	
	If InformationAboutAccounting.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
		InformationParameters.Title = NStr("vi = 'Thời hạn ghi giảm:';
											|ru = 'Срок списания:';
											|en = 'Write-off period:'; fa = 'Write-off period:';
											|it = 'Срок списания:';
											|pl = 'Write-off period:';
											|tr = 'Yazılma süresi:'");
		InformationParameters.Title1 = NStr("vi = 'Thời hạn ghi giảm (KTDN):';
											|ru = 'Срок списания (БУ):';
											|en = 'Write-off period (LA):'; fa = 'Write-off period (LA):';
											|it = 'Срок списания (БУ):';
											|pl = 'Write-off period (LA):';
											|tr = 'Yazılma süresi (GM):'");
		InformationParameters.Title2 = NStr("vi = 'Thời hạn ghi giảm (KTTh):';
											|ru = 'Срок списания (НУ):';
											|en = 'Write-off period (TA):'; fa = 'Write-off period (TA):';
											|it = 'Срок списания (НУ):';
											|pl = 'Write-off period (TA):';
											|tr = 'Yazılma süresi (VM):'");
		InformationParameters.Title3 = NStr("vi = 'Thời hạn ghi giảm (KTQT):';
											|ru = 'Срок списания (УУ):';
											|en = 'Write-off period (MA):'; fa = 'Write-off period (MA):';
											|it = 'Срок списания (УУ):';
											|pl = 'Write-off period (MA):';
											|tr = 'Yazılma süresi (YM):'");
	Else
		InformationParameters.Title = NStr("vi = 'Thời hạn sử dụng:';
											|ru = 'Срок использования:';
											|en = 'Useful life:'; fa = 'عمر مفید:';
											|it = 'Vita utile';
											|pl = 'Liczba miesięcy amortyzacji:';
											|tr = 'Kullanım süresi:'");
		InformationParameters.Title1 = NStr("vi = 'Thời hạn sử dụng (KTDN):';
											|ru = 'Срок использования (БУ):';
											|en = 'Useful life (LA):'; fa = 'Useful life (LA):';
											|it = 'Срок использования (БУ):';
											|pl = 'Useful life (LA):';
											|tr = 'Kullanım süresi (AC)'");
		InformationParameters.Title2 = NStr("vi = 'Thời lượng sử dụng (KTTh):';
											|ru = 'Срок использования (НУ):';
											|en = 'Useful life (TA):'; fa = 'Useful life (TA):';
											|it = 'Срок использования (НУ):';
											|pl = 'Useful life (TA):';
											|tr = 'Kullanım süresi (VM)'");
		InformationParameters.Title3 = NStr("vi = 'Thời hạn sử dụng (KTQT):';
											|ru = 'Срок использования (УУ):';
											|en = 'Useful life (MA):'; fa = 'Useful life (MA):';
											|it = 'Срок использования (УУ):';
											|pl = 'Useful life (MA):';
											|tr = 'Kullanım süresi (YM)'");
	EndIf; 
	
	PresentationOfInformation(InformationParameters, InformationAboutAccounting, PresentationOfInformation);
	
EndProcedure

// 
// Parameters:
//  InformationAboutAccounting - Structure - 
//  PresentationOfInformation - Structure -
Procedure PresentationOfInformationAboutDateOfWriteOff(InformationAboutAccounting, PresentationOfInformation) Export

	If InformationAboutAccounting = Undefined Then
		PresentationOfInformation.Insert("InformationRemovedFromTheRegister1", Undefined);
		PresentationOfInformation.Insert("InformationRemovedFromTheRegister2", Undefined);
		PresentationOfInformation.Insert("InformationRemovedFromTheRegister3", Undefined);
		Return;	
	EndIf;

	InformationParameters = InformationParameters();
	InformationParameters.NameOfInformationRecords = "InformationRemovedFromTheRegister";
	InformationParameters.Value1 = InformationAboutAccounting.DateOfDeRegistrationOfBU;
	InformationParameters.Value2 = InformationAboutAccounting.DateOfDeRegistrationWELL;
	InformationParameters.Value3 = InformationAboutAccounting.DateMaWasDeRegistered;
	InformationParameters.Document1 = InformationAboutAccounting.DeregistrationDocumentACC;
	InformationParameters.Document2 = InformationAboutAccounting.DeregistrationDocumentTA;
	InformationParameters.Document3 = InformationAboutAccounting.DeregistrationDocumentMA;
	InformationParameters.Title = NStr("vi = 'Ngày hủy đăng ký:';
										|ru = 'Дата снятия с учета:';
										|en = 'Deregistration date:'; fa = 'Deregistration date:';
										|it = 'Data di cancellazione:';
										|pl = 'Data wyrejestrowania:';
										|tr = 'Muhasebeden silinme tarihi:'");
	InformationParameters.Title1 = NStr("vi = 'Ngày bỏ trong hạch toán doanh nghiệp:';
										|ru = 'Дата снятия в бух. учете:';
										|en = 'Derecognition in local accounting date:'; fa = 'Derecognition in local accounting date:';
										|it = 'Data di rimozione in contabilità:';
										|pl = 'Data wyrejestrowania w ewidencji księgowej:';
										|tr = 'Genel muhasebeden silinme tarihi:'");
	InformationParameters.Title2 = NStr("vi = 'Ngày bỏ trong hạch toán thuế:';
										|ru = 'Дата снятия в нал. учете:';
										|en = 'Derecognition in tax accounting date:'; fa = 'Derecognition in tax accounting date:';
										|it = 'Data rimozione in contabilità fiscale:';
										|pl = 'Data wyrejestrowania w ewidencji podatkowej:';
										|tr = 'Vergi muhasebesinden silinme tarihi:'");
	InformationParameters.Title3 = NStr("vi = 'Ngày bỏ trong hạch toán quản trị:';
										|ru = 'Дата снятия в упр. учете:';
										|en = 'Derecognition in mgmt accounting date:'; fa = 'Derecognition in mgmt accounting date:';
										|it = 'Data rimozione in contabilità gestionale:';
										|pl = 'Data wyrejestrowania w ewidencji zarz.:';
										|tr = 'Yönetim muhasebesinden silinme tarihi:'");
	
	PresentationOfInformation(InformationParameters, InformationAboutAccounting, PresentationOfInformation);
	
EndProcedure

// 
// Parameters:
//  InformationAboutAccounting - Structure - 
//  PresentationOfInformation - Structure -
Procedure PresentationOfInformationOnLiquidationCosts(InformationAboutAccounting, PresentationOfInformation) Export
	
	If InformationAboutAccounting = Undefined
		Or InformationAboutAccounting.ResidualValueMan = 0
			And InformationAboutAccounting.ResidualValueLocal = 0 Then
		PresentationOfInformation.Insert("InformationLiquidationValue", Undefined);
		PresentationOfInformation.Insert("InformationLiquidationValueOfRegl", Undefined);
		Return;
	EndIf;
	
	If InformationAboutAccounting.StateOfTheUU = Enums.FixedAssetsStates.Recognized_
		Or InformationAboutAccounting.StateOfTheUU = Enums.IntangibleAssetsStates.PostedInFinancialAccounting
		Or InformationAboutAccounting.BUState = Enums.FixedAssetsStates.Recognized_
		Or InformationAboutAccounting.BUState = Enums.IntangibleAssetsStates.PostedInFinancialAccounting
		Or InformationAboutAccounting.StateTa = Enums.FixedAssetsStates.Recognized_
		Or InformationAboutAccounting.StateTa = Enums.IntangibleAssetsStates.PostedInFinancialAccounting
		Or InformationAboutAccounting.StateOfTheUU = Enums.FixedAssetsStates.TakenOffBooks
		Or InformationAboutAccounting.StateOfTheUU = Enums.IntangibleAssetsStates.WrittenOff_
		Or InformationAboutAccounting.BUState = Enums.FixedAssetsStates.TakenOffBooks
		Or InformationAboutAccounting.BUState = Enums.IntangibleAssetsStates.WrittenOff_
		Or InformationAboutAccounting.StateTa = Enums.FixedAssetsStates.TakenOffBooks
		Or InformationAboutAccounting.StateTa = Enums.IntangibleAssetsStates.WrittenOff_ Then
		
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(InformationAboutAccounting.Organization);
		CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
		
		ComplCurrencyPresentation = String(ComplCurrency);
		CurrencyOfManPresentation = String(CurrencyOfMan);
		
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently();
		
		If InformationAboutAccounting.ResidualValueMan = InformationAboutAccounting.ResidualValueLocal
			And ComplCurrency = CurrencyOfMan
			And Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently() Then
			
			PresentationOfInformationOnAmount(
				"InformationLiquidationValue", 
				NStr("vi = 'Giá trị thanh lý:';
					|ru = 'Ликвидационная стоимость:';
					|en = 'Residual value:'; fa = 'Residual value:';
					|it = 'Prezzo di liquidazione';
					|pl = 'Cena likwidacyjna:';
					|tr = 'Artık değer'"), 
				InformationAboutAccounting.ResidualValueMan, 
				CurrencyOfManPresentation, 
				PresentationOfInformation); 
		
			PresentationOfInformation.Insert("InformationLiquidationValueOfRegl", Undefined);
		
		Else
		
			PresentationOfInformationOnAmount(
				"InformationLiquidationValue", 
				NStr("vi = 'Giá trị thanh lý (quản trị):';
					|ru = 'Ликвидационная стоимость (упр):';
					|en = 'Residual value (mgmt):'; fa = 'Residual value (mgmt):';
					|it = 'Prezzo di liquidazione';
					|pl = 'Residual value (mgmt):';
					|tr = 'Artık değer (yönetim):'"), 
				InformationAboutAccounting.ResidualValueMan, 
				CurrencyOfManPresentation, 
				PresentationOfInformation); 
			
			PresentationOfInformationOnAmount(
				"InformationLiquidationValueOfRegl", 
				NStr("vi = 'Giá trị thanh lý (tài chính):';
					|ru = 'Ликвидационная стоимость (регл):';
					|en = 'Residual value (local):'; fa = 'ارزش باقی‌مانده (محلی):';
					|it = 'Prezzo di liquidazione';
					|pl = 'Residual value (local):';
					|tr = 'Artık değer (yerel):'"), 
				InformationAboutAccounting.ResidualValueLocal, 
				ComplCurrencyPresentation, 
				PresentationOfInformation); 
				
		EndIf;
		
	Else
		PresentationOfInformation.Insert("InformationLiquidationValue", Undefined);
		PresentationOfInformation.Insert("InformationLiquidationValueOfRegl", Undefined);
	EndIf;
		
EndProcedure

// 
// Parameters:
//  NameOfInformationRecords - String - 
//  Title - String - 
//  Sum - Number - 
//  CurrencyPresentation - String - 
//  PresentationOfInformation - Structure - 
Procedure PresentationOfInformationOnAmount(NameOfInformationRecords, Title, Sum, CurrencyPresentation, PresentationOfInformation) Export

	Result = New Array;
	Result.Add(Title);
	Result.Add(" ");
	Result.Add(String(Sum));
	Result.Add(" ");
	Result.Add(CurrencyPresentation);

	PresentationOfInformation.Insert(NameOfInformationRecords, Result);
	
EndProcedure

// 
// Parameters:
//  NameOfInformationRecords - String - Name of Information
//  Title - String - Title
//  Ref - AnyRef - 
//  RepresentationOfTheReference - String - 
//  PresentationOfInformation - Structure - 
Procedure PresentationOfInformationByLink(NameOfInformationRecords, Title, Ref, RepresentationOfTheReference, PresentationOfInformation) Export
	
	Result = New Array;
	
	If ValueIsFilled(Ref) Then
		Result.Add(Title);
		Result.Add(" ");
		If ValueIsFilled(Ref) Then
			ObjectReference = GetURL(Ref);
		Else
			ObjectReference = Undefined;
		EndIf;
		Result.Add(New FormattedString(RepresentationOfTheReference,,,, ObjectReference));
		Result.Add(" ");
	EndIf;
			
	PresentationOfInformation.Insert(NameOfInformationRecords, Result);
	
EndProcedure

Procedure PresentationOfInformation(InformationParameters, InformationAboutAccounting, PresentationOfInformation)
	
	If InformationAboutAccounting = Undefined Then
		PresentationOfInformation.Insert(InformationParameters.NameOfInformationRecords + "1", Undefined);
		PresentationOfInformation.Insert(InformationParameters.NameOfInformationRecords + "2", Undefined);
		PresentationOfInformation.Insert(InformationParameters.NameOfInformationRecords + "3", Undefined);
		Return;
	EndIf;
	
	ComplianceCAAccountingIsKept = ComplianceCAAccountingIsKept();
	
	PresentationOfInformation1 = New Array;
	PresentationOfInformation2 = New Array;
	PresentationOfInformation3 = New Array;
	
	If InformationAboutAccounting.StateOfTheUU = Enums.FixedAssetsStates.Recognized_
		Or InformationAboutAccounting.BUState = Enums.FixedAssetsStates.Recognized_
		Or InformationAboutAccounting.StateTa = Enums.FixedAssetsStates.Recognized_
		Or InformationAboutAccounting.StateOfTheUU = Enums.FixedAssetsStates.TakenOffBooks
		Or InformationAboutAccounting.BUState = Enums.FixedAssetsStates.TakenOffBooks
		Or InformationAboutAccounting.StateTa = Enums.FixedAssetsStates.TakenOffBooks
		Or InformationAboutAccounting.StateOfTheUU = Enums.IntangibleAssetsStates.PostedInFinancialAccounting
		Or InformationAboutAccounting.BUState = Enums.IntangibleAssetsStates.PostedInFinancialAccounting
		Or InformationAboutAccounting.StateTa = Enums.IntangibleAssetsStates.PostedInFinancialAccounting
		Or InformationAboutAccounting.StateOfTheUU = Enums.IntangibleAssetsStates.WrittenOff_
		Or InformationAboutAccounting.BUState = Enums.IntangibleAssetsStates.WrittenOff_
		Or InformationAboutAccounting.StateTa = Enums.IntangibleAssetsStates.WrittenOff_ Then
		
		If ValueIsFilled(InformationParameters.Value1) 
				And ValueIsFilled(InformationParameters.Value2)
				And ValueIsFilled(InformationParameters.Value3)
				And InformationParameters.Value1 = InformationParameters.Value2
				And InformationParameters.Value1 = InformationParameters.Value3
			Or ValueIsFilled(InformationParameters.Value1) 
				And ValueIsFilled(InformationParameters.Value3)
				And InformationParameters.Value3 = InformationParameters.Value3
				And Not ComplianceCAAccountingIsKept Then
		
			PresentationOfInformation1.Add(InformationParameters.Title);
			PresentationOfInformation1.Add(" ");
			If TypeOf(InformationParameters.Value1) = Type("Date") Then
				ValuePresentation = Format(InformationParameters.Value1, "DLF=D");
			Else
				ValuePresentation = InformationParameters.Value1;
			EndIf;
			If ValueIsFilled(InformationParameters.Document1) Then
				ObjectReference = GetURL(InformationParameters.Document1);
				PresentationOfInformation1.Add(New FormattedString(ValuePresentation,,,, ObjectReference));
			Else
				PresentationOfInformation1.Add(ValuePresentation);
			EndIf;
			
		Else
			
			If ValueIsFilled(InformationParameters.Value1) Then
					
				PresentationOfInformation1.Add(InformationParameters.Title1);
				PresentationOfInformation1.Add(" ");
				If TypeOf(InformationParameters.Value1) = Type("Date") Then
					ValuePresentation = Format(InformationParameters.Value1, "DLF=D");
				Else
					ValuePresentation = InformationParameters.Value1;
				EndIf;
				If ValueIsFilled(InformationParameters.Document1) Then
					ObjectReference = GetURL(InformationParameters.Document1);
				Else
					ObjectReference = Undefined;
				EndIf;
				PresentationOfInformation1.Add(New FormattedString(ValuePresentation,,,, ObjectReference));
			EndIf;
			
			If ValueIsFilled(InformationParameters.Value2) Then
					
				PresentationOfInformation2.Add(InformationParameters.Title2);
				PresentationOfInformation2.Add(" ");
				If TypeOf(InformationParameters.Value2) = Type("Date") Then
					ValuePresentation = Format(InformationParameters.Value2, "DLF=D");
				Else
					ValuePresentation = InformationParameters.Value2;
				EndIf;
				If ValueIsFilled(InformationParameters.Document2) Then
					ObjectReference = GetURL(InformationParameters.Document2);
				Else
					ObjectReference = Undefined;
				EndIf;
				PresentationOfInformation2.Add(New FormattedString(ValuePresentation,,,, ObjectReference));
			EndIf;
			
			If ValueIsFilled(InformationParameters.Value3) Then
				
				PresentationOfInformation3.Add(InformationParameters.Title3);
				PresentationOfInformation3.Add(" ");
				If TypeOf(InformationParameters.Value3) = Type("Date") Then
					ValuePresentation = Format(InformationParameters.Value3, "DLF=D");
				Else
					ValuePresentation = InformationParameters.Value3;
				EndIf;
				If ValueIsFilled(InformationParameters.Document3) Then
					ObjectReference = GetURL(InformationParameters.Document3);
				Else
					ObjectReference = Undefined;
				EndIf;
				PresentationOfInformation3.Add(New FormattedString(ValuePresentation,,,, ObjectReference));
			EndIf; 
			
		EndIf;
		
	ElsIf InformationAboutAccounting.BUState = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting
		Or InformationAboutAccounting.StateOfTheUU = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting Then
		 
		PresentationOfInformation1.Add(InformationParameters.Title);
		PresentationOfInformation1.Add(" ");
		If TypeOf(InformationParameters.Value1) = Type("Date") Then
			ValuePresentation = Format(InformationParameters.Value1, "DLF=D");
		Else
			ValuePresentation = InformationParameters.Value1;
		EndIf;
		If ValueIsFilled(InformationParameters.Document1) Then
			ObjectReference = GetURL(InformationParameters.Document1);
			PresentationOfInformation1.Add(New FormattedString(ValuePresentation,,,, ObjectReference));
		Else
			PresentationOfInformation1.Add(ValuePresentation);
		EndIf;
		 
	ElsIf ValueIsFilled(InformationParameters.Action1) Then
		 
		PresentationOfInformation1.Add(InformationParameters.Action1);
		
	EndIf;
	
	PresentationOfInformation.Insert(InformationParameters.NameOfInformationRecords + "1", PresentationOfInformation1);
	PresentationOfInformation.Insert(InformationParameters.NameOfInformationRecords + "2", PresentationOfInformation2);
	PresentationOfInformation.Insert(InformationParameters.NameOfInformationRecords + "3", PresentationOfInformation3);
	
EndProcedure

Function InformationParameters()
	
	InformationParameters = New Structure;
	
	InformationParameters.Insert("Value1", "");
	InformationParameters.Insert("Value2", "");
	InformationParameters.Insert("Value3", "");
	
	InformationParameters.Insert("Title", "");
	InformationParameters.Insert("Title1", "");
	InformationParameters.Insert("Title2", "");
	InformationParameters.Insert("Title3", "");
	
	InformationParameters.Insert("Document1", Undefined);
	InformationParameters.Insert("Document2", Undefined);
	InformationParameters.Insert("Document3", Undefined);
	
	InformationParameters.Insert("NameOfInformationRecords", "");
	InformationParameters.Insert("Action1", Undefined);
	
	Return InformationParameters;
	
EndFunction

// 
// Parameters:
//  RegisterName - String - 
//  TableName - String - 
//  NameOfParameterPeriodsTable - String -
//  AccountingObject - String -
//  ListOfRequests - Array of String - 
Procedure AddQueryTextHelpTablesDepreciationCalculation(RegisterName, TableName, NameOfParameterPeriodsTable, AccountingObject, ListOfRequests) Export

	RegisterSupportsCorrection = RegisterSupportsCorrection(RegisterName);

	QueryText =
	"SELECT
	|	MainTable.Period AS Period,
	|	MainTable.ParameterPeriod AS ParameterPeriod,
	|	MainTable.EndOfParameterPeriod AS EndOfParameterPeriod,
	|	MainTable.Organization AS Organization,
	|	MainTable.AccountingObjectField AS AccountingObjectField,
	|
	|	MAX(RegisterTable.Period) AS CutOffPeriodOfLatter,
	|	MAX(BEGINOFPERIOD(RegisterTable.Period, DAY)) AS PeriodStartOfDay
	|
	|INTO RegisterTable_SectionOfRecent_Period
	|
	|FROM
	|	TableOfParameterPeriods AS MainTable
	|
	|		INNER JOIN RegisterTableSource AS RegisterTable
	|		ON RegisterTable.Organization = MainTable.Organization
	|			AND RegisterTable.AccountingObjectField = MainTable.AccountingObjectField
	|			AND RegisterTable.Period <= MainTable.ParameterPeriod
	|			AND RegisterTable.CorrectionDate <= MainTable.EndOfParameterPeriod
	|			AND RegisterTable.Active
	|
	|GROUP BY
	|	MainTable.Period,
	|	MainTable.ParameterPeriod,
	|	MainTable.EndOfParameterPeriod,
	|	MainTable.Organization,
	|	MainTable.AccountingObjectField
	|
	|INDEX BY
	|	AccountingObjectField,
	|	Organization,
	|	CutOffPeriodOfLatter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MainTable.Period AS Period,
	|	MainTable.ParameterPeriod AS ParameterPeriod,
	|	MainTable.Organization AS Organization,
	|	MainTable.AccountingObjectField AS AccountingObjectField,
	|
	|	CASE
	|		WHEN MAX(ISNULL(RegisterTable.CorrectionDate, DATETIME(1,1,1))) <> DATETIME(1,1,1)
	|			THEN BEGINOFPERIOD(MainTable.CutOffPeriodOfLatter, DAY)
	|		ELSE MainTable.CutOffPeriodOfLatter 
	|	END AS CutOffPeriodOfLatter,
	|
	|	MAX(ISNULL(RegisterTable.CorrectionDate, DATETIME(1,1,1))) AS DateOfCorrectionOfCutOfLast
	|
	|INTO RegisterTable_SectionOfRecent_CorrectionDate
	|
	|FROM
	|	RegisterTable_SectionOfRecent_Period AS MainTable
	|
	|		LEFT JOIN RegisterTableSource AS RegisterTable
	|		ON RegisterTable.Organization = MainTable.Organization
	|			AND RegisterTable.AccountingObjectField = MainTable.AccountingObjectField
	|			AND RegisterTable.Period = MainTable.PeriodStartOfDay
	|			AND RegisterTable.CorrectionDate <= MainTable.EndOfParameterPeriod
	|			AND RegisterTable.CorrectionDate <> DATETIME(1,1,1)
	|			AND RegisterTable.Active
	|
	|GROUP BY
	|	MainTable.Period,
	|	MainTable.ParameterPeriod,
	|	MainTable.Organization,
	|	MainTable.AccountingObjectField,
	|	MainTable.CutOffPeriodOfLatter
	|
	|INDEX BY
	|	AccountingObjectField,
	|	Organization,
	|	CutOffPeriodOfLatter	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MainTable.Period AS Period,
	|	MainTable.ParameterPeriod AS ParameterPeriod,
	|	MainTable.Organization AS Organization,
	|	MainTable.AccountingObjectField AS AccountingObjectField,
	|	MainTable.CutOffPeriodOfLatter AS CutOffPeriodOfLatter,
	|
	|	MAX(RegisterTable.Recorder) AS LoggerOfSliceOfLast
	|
	|INTO RegisterTable_SliceOfLatest_Logger
	|
	|FROM
	|	RegisterTable_SectionOfRecent_CorrectionDate AS MainTable
	|
	|		INNER JOIN RegisterTableSource AS RegisterTable
	|		ON RegisterTable.Organization = MainTable.Organization
	|			AND RegisterTable.AccountingObjectField = MainTable.AccountingObjectField
	|			AND RegisterTable.Period = MainTable.CutOffPeriodOfLatter
	|			AND RegisterTable.CorrectionDate = MainTable.DateOfCorrectionOfCutOfLast
	|
	|GROUP BY
	|	MainTable.Period,
	|	MainTable.ParameterPeriod,
	|	MainTable.Organization,
	|	MainTable.AccountingObjectField,
	|	MainTable.CutOffPeriodOfLatter
	|
	|INDEX BY
	|	AccountingObjectField,
	|	Organization,
	|	CutOffPeriodOfLatter	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MainTable.Period AS Period,
	|
	|	&CaseFieldText
	|
	|INTO TableName
	|
	|FROM
	|	RegisterTable_SliceOfLatest_Logger AS MainTable
	|
	|		INNER JOIN RegisterTableSource AS RegisterTable
	|		ON RegisterTable.Organization = MainTable.Organization
	|			AND RegisterTable.AccountingObjectField = MainTable.AccountingObjectField
	|			AND RegisterTable.Period = MainTable.CutOffPeriodOfLatter
	|			AND RegisterTable.Recorder = MainTable.LoggerOfSliceOfLast
	|
	|INDEX BY
	|	Period,
	|	AccountingObjectField
	|	,CompanyIndex
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RegisterTable_SectionOfRecent_Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RegisterTable_SectionOfRecent_CorrectionDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RegisterTable_SliceOfLatest_Logger
	|";
	
	CaseFieldText = CaseFieldText(RegisterName);
	QueryText = StrReplace(QueryText, "&CaseFieldText", CaseFieldText);
	
	If Not ThereIsCompanyInRegister(RegisterName) Then
		QueryText = StrReplace(QueryText, "(RegisterTable.Organization = MainTable.Organization)", "TRUE");
		QueryText = StrReplace(QueryText, ",CompanyIndex", "");
	Else
		QueryText = StrReplace(QueryText, ",CompanyIndex", ",Organization");
	EndIf;
	
	If Not RegisterSupportsCorrection Then
		QueryText = StrReplace(QueryText, "RegisterTable.CorrectionDate", "DATETIME(1,1,1)");
	EndIf;
	
	QueryText = StrReplace(QueryText, "RegisterTableSource", "InformationRegister." + RegisterName);
	QueryText = StrReplace(QueryText, "TableOfParameterPeriods", NameOfParameterPeriodsTable);
	QueryText = StrReplace(QueryText, "TableName", TableName);
	QueryText = StrReplace(QueryText, "AccountingObjectField", AccountingObject);
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

// 
// Parameters:
//  RegisterName - String - Register name
//  CalculatingFields - Structure -
//  DonTAddFields - Array of String - Don't Add Fields
// 
// Returns:
//  String -
Function CaseFieldText(RegisterName, CalculatingFields = Undefined, DonTAddFields = Undefined) Export
	
	RegisterMetadata = Metadata.InformationRegisters[RegisterName];
	
	If CalculatingFields = Undefined Then
		CalculatingFields = New Structure;
	EndIf;
	
	If DonTAddFields = Undefined Then
		DonTAddFields = New Array;
	EndIf;
	
	FieldList = New Array;
	If RegisterMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
		FieldList.Add("	RegisterTable.Recorder AS Recorder");
	EndIf;
	
	For Each MetadataDimensions In RegisterMetadata.Dimensions Do
		If DonTAddFields.Find(Upper(MetadataDimensions.Name)) = Undefined Then
			FieldList.Add("	RegisterTable." + MetadataDimensions.Name + " AS " + MetadataDimensions.Name);
		EndIf;
	EndDo;
	
	For Each MetadataDimensions In RegisterMetadata.Resources Do
		If DonTAddFields.Find(Upper(MetadataDimensions.Name)) = Undefined Then
			If CalculatingFields.Property(MetadataDimensions.Name) Then
				PathToField = CalculatingFields[MetadataDimensions.Name];
			Else
				PathToField = "	RegisterTable." + MetadataDimensions.Name
			EndIf; 
			FieldList.Add(PathToField + " AS " + MetadataDimensions.Name);
		EndIf;
	EndDo; 
	
	FieldSeparator = ",
	|	";
	FieldTexts = StrConcat(FieldList, FieldSeparator);
	
	Return FieldTexts;
	
EndFunction

// 
// Parameters:
//  RegisterName - String - Register name
// 
// Returns:
//  Boolean - True if there is a company in the register
Function ThereIsCompanyInRegister(RegisterName) Export
	
	RegisterMetadata = Metadata.InformationRegisters[RegisterName];
	Return RegisterMetadata.Dimensions.Find("Organization") <> Undefined;
	
EndFunction

// Sets the Presentation of the Date field in lists containing Attributes with the Date and time composition.
//
// Parameters:
//   Form - ClientApplicationForm - form with a list.
//   FullAttributeName - String - full path to the "date" type of information in the format " < Listname>.<Field name>".
//   TagName - String - name of the form element associated with the "date" list item.
//   NameOfPropsShowTimeOfDocuments - String - the name of the Attribute that determines whether to display the time.
//
Procedure SetDateFieldConditionalAppearance(Form, FullAttributeName = "List.Date", TagName = "Date", NameOfPropsShowTimeOfDocuments = "") Export
	
	CommonClientServer.CheckParameter(
		"StandardSubsystemsServer.SetDateFieldConditionalAppearance",
		"ThisObject", 
		Form, 
		Type("ClientApplicationForm"));
	
	FullNameParts1 = StrSplit(FullAttributeName, ".");
	
	If FullNameParts1.Count() <> 2 Then 
		// Invalid value of the Request Fullname parameter.
		// The name of the props must be in the format ""<Subscription name>.<Field name>""'");
		Return;
	EndIf;
	
	ListName = FullNameParts1[0];
	AttributeList = Form[ListName];
	
	If TypeOf(AttributeList) = Type("DynamicList") Then 
		// The dynamic list allows you to set a conditional layout using your own linker.
		// In this case, the Element name parameter is ignored, because the dynamic list linker
		// does not know how the list details will be displayed, because the path to the props and the selection and design 
		// values is the name of the dynamic list props.
		ConditionalAppearance = AttributeList.ConditionalAppearance;
		AttributePath1 = FullNameParts1[1];
		FormattedFieldName = AttributePath1;
	Else 
		// The rest of the lists, for example, are given by the tree form:
		// they do not have their own linker, therefore they use the linker of the form itself.
		ConditionalAppearance = Form.ConditionalAppearance;
		AttributePath1 = FullAttributeName;
		FormattedFieldName = TagName;
	EndIf;
	
	If Not ValueIsFilled(ConditionalAppearance.UserSettingID) Then
		ConditionalAppearance.UserSettingID = "MainAppearance";
	EndIf;
	
	// Date representation.
	AppearanceItem = ConditionalAppearance.Items.Add();
	AppearanceItem.Use = True;
	AppearanceItem.Appearance.SetParameterValue("Format", "DLF=D");
	
	FormattedField = AppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(FormattedFieldName);
	
	If ValueIsFilled(NameOfPropsShowTimeOfDocuments) Then
		FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue  = New DataCompositionField(NameOfPropsShowTimeOfDocuments);
		FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = False;
	EndIf;
	
	// The date representation is today.
	AppearanceItem = ConditionalAppearance.Items.Add();
	AppearanceItem.Use = True;
	AppearanceItem.Appearance.SetParameterValue("Format", NStr("vi = 'DF=HH:mm';
																|ru = 'ДФ=ЧЧ:мм';
																|en = 'DF=hh:mm'; fa = 'DF=hh:mm';
																|it = 'ДФ=ЧЧ:мм';
																|pl = 'DF=hh:mm';
																|tr = 'DF=HH:mm'"));
	
	FormattedField = AppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(FormattedFieldName);
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField(AttributePath1);
	FilterElement.ComparisonType   = DataCompositionComparisonType.GreaterOrEqual;
	FilterElement.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField(AttributePath1);
	FilterElement.ComparisonType   = DataCompositionComparisonType.Less;
	FilterElement.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
	If ValueIsFilled(NameOfPropsShowTimeOfDocuments) Then
		FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue  = New DataCompositionField(NameOfPropsShowTimeOfDocuments);
		FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = False;
	EndIf;
	
EndProcedure

Function FAExpensesRecordingMethods(Date, FixedAsset, Organization)
	
	WaysToReflectExpenses = New Structure;
	WaysToReflectExpenses.Insert("ExpenseRecordMethodAC", Catalogs.WaysToReflectExpenses.EmptyRef());
	WaysToReflectExpenses.Insert("ExpenseRecordMethodTA", Catalogs.WaysToReflectExpenses.EmptyRef());
	WaysToReflectExpenses.Insert("MethodForReflectingMaExpenses", Catalogs.WaysToReflectExpenses.EmptyRef());
	
	QueryText =
	"SELECT
	|	AccountingProcedureForOSBU.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
	|	AccountingProcedureForOSBU.ExpenseRecordMethodTA AS ExpenseRecordMethodTA,
	|	FixedAssetsAccountingProcedureManagementAccounting.ExpensesPostingMethod AS MethodForReflectingMaExpenses
	|
	|FROM
	|	Catalog.Assets AS List
	|	
	|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|			&Date, 
	|			CorrectionDate = DATETIME(1,1,1)
	|			AND Organization = &Organization
	|			AND FixedAsset = &FixedAsset) AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.FixedAsset = List.Ref
	|	
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&Date, 
	|			CorrectionDate = DATETIME(1,1,1)
	|			AND Organization = &Organization
	|			AND FixedAsset = &FixedAsset) AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = List.Ref
	|
	|WHERE
	|	List.Ref = &FixedAsset
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("FixedAsset", FixedAsset);
	
	Result = Query.Execute();
	Selection = Result.Select();
	If Selection.Next() Then
		FillPropertyValues(WaysToReflectExpenses, Selection);
	EndIf;
	
	Return WaysToReflectExpenses;
	
EndFunction

Function IAExpensesRecordingMethods(Date, IntangibleAsset, Organization)
	
	WaysToReflectExpenses = New Structure;
	WaysToReflectExpenses.Insert("ExpenseRecordMethodAC", Catalogs.WaysToReflectExpenses.EmptyRef());
	WaysToReflectExpenses.Insert("ExpenseRecordMethodTA", Catalogs.WaysToReflectExpenses.EmptyRef());
	WaysToReflectExpenses.Insert("MethodForReflectingMaExpenses", Catalogs.WaysToReflectExpenses.EmptyRef());
	
	QueryText =
	"SELECT
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
	|	IABookkeepingProcedureBookkeepingAndTaxAccounting.ExpenseRecordMethodTA AS ExpenseRecordMethodTA,
	|	IntangibleAssetsAccountingProcedureManagementAccounting.ExpensesPostingMethod AS MethodForReflectingMaExpenses
	|
	|FROM
	|	Catalog.IntangibleAssets AS List
	|	
	|		LEFT JOIN InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
	|			&Date, 
	|			Organization = &Organization
	|			AND IntangibleAsset = &IntangibleAsset) AS IABookkeepingProcedureBookkeepingAndTaxAccounting
	|		ON IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset = List.Ref
	|	
	|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&Date, 
	|			Organization = &Organization
	|			AND IntangibleAsset = &IntangibleAsset) AS IntangibleAssetsAccountingProcedureManagementAccounting
	|		ON IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset = List.Ref
	|
	|WHERE
	|	List.Ref = &IntangibleAsset
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("IntangibleAsset", IntangibleAsset);
	
	Result = Query.Execute();
	Selection = Result.Select();
	If Selection.Next() Then
		FillPropertyValues(WaysToReflectExpenses, Selection);
	EndIf;
	
	Return WaysToReflectExpenses;
	
EndFunction

Procedure CheckFAType(AvailableFATypes, Object, TSName, FieldName, Cancel) Export
	
	QueryText = 
	"SELECT
	|	Assets.Ref AS Ref,
	|	Assets.Presentation AS Presentation
	|FROM
	|	Catalog.Assets AS Assets
	|
	|WHERE
	|	Assets.Ref IN (&ListOfFA)
	|	AND NOT Assets.OSType IN (&AvailableFATypes)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfFA", ?(TSName <> Undefined, Object[TSName].UnloadColumn(FieldName), Object[FieldName]));
	Query.SetParameter("AvailableFATypes", AvailableFATypes);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	CheckResult = New Map();
	Selection = Result.Select();
	While Selection.Next() Do
		CheckResult.Insert(Selection.Ref, Selection.Presentation);
	EndDo;
	
	If TSName <> Undefined Then
		
		For Each RowData In Object[TSName] Do
			
			Presentation = CheckResult.Get(RowData[FieldName]);

			If Presentation <> Undefined Then
				
				MessageText = NStr("vi = 'Kiểu TSCĐ hữu hình %1 không được hỗ trợ trong chứng từ, cần chọn TSCĐ hữu hình khác hoặc chỉnh sửa kiểu TSCĐ hữu hình.';
									|ru = 'Тип основного средства %1 не поддерживается в документе, необходимо выбрать другое основное средство или исправить тип ОС.';
									|en = '%1 fixed asset type is not supported in the document. Select another fixed asset or correct the fixed asset type.'; fa = '%1 fixed asset type is not supported in the document. Select another fixed asset or correct the fixed asset type.';
									|it = '%1 fixed asset type is not supported in the document. Select another fixed asset or correct the fixed asset type.';
									|pl = '%1 fixed asset type is not supported in the document. Select another fixed asset or correct the fixed asset type.';
									|tr = '%1 sabit kıymet türü belgede desteklenmiyor. Başka bir sabit kıymet seçmeli veya sabit kıymet türünü düzeltmelisiniz.'");
				MessageText = StrTemplate(MessageText, Presentation);
				Field = CommonClientServer.PathToTabularSection(TSName, RowData.LineNumber, FieldName);
				Common.MessageToUser(MessageText, Object, Field, "", Cancel);
			
			EndIf;
			
		EndDo;
	
	Else
		
		Presentation = CheckResult.Get(Object[FieldName]);
		
		If Presentation <> Undefined Then
			MessageText = NStr("vi = 'Kiểu TSCĐ hữu hình %1 không được hỗ trợ trong chứng từ, cần chọn TSCĐ hữu hình khác hoặc chỉnh sửa kiểu TSCĐ hữu hình.';
								|ru = 'Тип основного средства %1 не поддерживается в документе, необходимо выбрать другое основное средство или исправить тип ОС.';
								|en = '%1 fixed asset type is not supported in the document. Select another fixed asset or correct the fixed asset type.'; fa = '%1 fixed asset type is not supported in the document. Select another fixed asset or correct the fixed asset type.';
								|it = '%1 fixed asset type is not supported in the document. Select another fixed asset or correct the fixed asset type.';
								|pl = '%1 fixed asset type is not supported in the document. Select another fixed asset or correct the fixed asset type.';
								|tr = '%1 sabit kıymet türü belgede desteklenmiyor. Başka bir sabit kıymet seçmeli veya sabit kıymet türünü düzeltmelisiniz.'");
			MessageText = StrTemplate(MessageText, Presentation);
			Common.MessageToUser(MessageText, Object, FieldName,, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Function ThereAreObjectsThatWereWrittenOffWhenTheyWereAcceptedForAccounting(Ref, Date, Organization, ListOfFA) Export

	QueryText = 
	"SELECT TOP 1
	|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset
	|FROM
	|	InformationRegister.InitialFixedAssetsInformation.SliceLast(
	|			&Date,
	|			Recorder <> &Ref
	|				AND CorrectionDate = DATETIME(1,1,1)
	|				AND Organization = &Organization
	|				AND FixedAsset IN (&ListOfFA)) AS InitialFixedAssetsInformation
	|WHERE
	|	InitialFixedAssetsInformation.AccountingProcedureTA = VALUE(Enum.ProcedureOfIncludingFixedAssetCostInExpensesTA.DeductionInExpensesOnRecognition)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ListOfFA", ListOfFA);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();

EndFunction

Procedure DeleteEmptySelection(FilterName, Parameters) Export

	If Parameters = Undefined
		Or Not Parameters.Property("Filter") Then
		Return;
	EndIf;

	FiltersList = StrSplit(FilterName, ",");
	
	For Each Item In FiltersList Do
		
		If Parameters.Filter.Property(Item)
			And Not ValueIsFilled(Parameters.Filter[Item]) Then
			Parameters.Filter.Delete(Item);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SetSelectionInQuickAccess(FilterName, Parameters, List) Export
	
	If Parameters = Undefined
		Or Not Parameters.Property("Filter") Then
		Return;
	EndIf;

	FiltersList = StrSplit(FilterName, ",");

	For Each Item In FiltersList Do
		
		If Not Parameters.Filter.Property(Item)
			Or Not ValueIsFilled(Parameters.Filter[Item]) Then
			Continue;
		EndIf;
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			Item,
			Parameters.Filter[Item],
			DataCompositionComparisonType.Equal,,
			True,
			DataCompositionSettingsItemViewMode.QuickAccess);
		
		Parameters.Filter.Delete(Item);
		
	EndDo;
	
EndProcedure

// 
// Parameters:
//  LetteringOfForm - FormDecoration - 
//
Procedure InstallInscriptionOutdatedFunctionality(LetteringOfForm) Export
	
	If Not GetFunctionalOption("UseNonCurrentAssets2_2") Then
		Return;
	EndIf;
	
	LetteringOfForm.TextColor = StyleColors.SpecialTextColor;
	
	If GetFunctionalOption("UseNonCurrentAssets2_4") Then
		LetteringOfForm.Title = NStr("vi = 'Lưu ý! Chức năng kế toán tài sản dài hạn phiên bản 2.2 sẽ bị xóa trong phiên bản 2.6.3.';
									|ru = 'Внимание! Функциональность учета внеоборотных активов версии 2.2 будет удалена в версии 2.6.3.';
									|en = 'Important. Fixed and intangible assets accounting version 2.2 will be removed in version 2.6.3.'; fa = 'Important. Fixed and intangible assets accounting version 2.2 will be removed in version 2.6.3.';
									|it = 'Important. Fixed and intangible assets accounting version 2.2 will be removed in version 2.6.3.';
									|pl = 'Important. Fixed and intangible assets accounting version 2.2 will be removed in version 2.6.3.';
									|tr = 'Dikkat! 2.2 sürümünün duran varlık muhasebesi işlevselliği 2.6.3 sürümünde kaldırılacaktır.'");
	Else
		LetteringOfForm.Title = NStr("vi = 'Lưu ý! Chức năng kế toán tài sản dài hạn phiên bản 2.2 sẽ bị xóa trong phiên bản 2.6.3. Vui lòng chuyển sang phiên bản kế toán 2.4.';
									|ru = 'Внимание! Функциональность учета внеоборотных активов версии 2.2 будет удалена в версии 2.6.3. Пожалуйста, перейдите на версию учета 2.4.';
									|en = 'Important. Fixed and intangible assets accounting version 2.2 will be removed in version 2.6.3. Please upgrade to version 2.4.'; fa = 'Important. Fixed and intangible assets accounting version 2.2 will be removed in version 2.6.3. Please upgrade to version 2.4.';
									|it = 'Important. Fixed and intangible assets accounting version 2.2 will be removed in version 2.6.3. Please upgrade to version 2.4.';
									|pl = 'Important. Fixed and intangible assets accounting version 2.2 will be removed in version 2.6.3. Please upgrade to version 2.4.';
									|tr = 'Dikkat! 2.2 sürümünün duran varlık muhasebesi işlevselliği 2.6.3 sürümünde kaldırılacaktır. Lütfen 2.4 muhasebe sürümüne geçiş yapın.'");
	EndIf;
	
EndProcedure

// Executes the request and performs the measurement if necessary.
// 
// Parameters:
//  Query - Query
//  ListOfRequests - ValueList, Undefined - List of requests
//  PerformMeasurement - Boolean - Perform measurement
// 
// Returns:
//  QueryResult - query result
Function ExecuteQuery(Query, ListOfRequests = Undefined, PerformMeasurement = False) Export
	
	If PerformMeasurement Then
		
		If ListOfRequests <> Undefined Then
			
			For Cnt = 0 To ListOfRequests.UBound() Do
	
				KeyOperation = "ExecuteQuery.Query" + Format(Cnt, "ND=3; NZ=000; NLZ=; NG=;");
				
				Query.Text = ListOfRequests[Cnt];
	
				BeginTime = PerformanceMonitor.StartTimeMeasurement();
				Result = Query.Execute();
				PerformanceMonitor.EndTimeMeasurement(KeyOperation, BeginTime,,, True);
				
			EndDo;
			
		Else
	
			KeyOperation = "ExecuteQuery.Query";
			
			BeginTime = PerformanceMonitor.StartTimeMeasurement();
			Result = Query.Execute();
			PerformanceMonitor.EndTimeMeasurement(KeyOperation, BeginTime,,, True);
			
		EndIf;
		
	Else
		
		If ListOfRequests <> Undefined Then
			Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
		EndIf;
		
		Result = Query.Execute();

	EndIf;

	Return Result;
	
EndFunction

#EndRegion

#EndRegion
