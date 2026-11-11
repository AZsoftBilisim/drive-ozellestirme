
#Region Public

// Returns the available terms for the granting of discounts (extra charges)
//
// Returns:
//  Array - Available conditions for providing discounts (margins).
//
Function AvailableConditionsForDiscountsMarkups() Export
	
	AvailableTermsOfService = New ValueList;
	AvailableTermsOfService.Add(Enums.DiscountMarkupTerms.ForOneTimeSalesVolume);
	AvailableTermsOfService.Add(Enums.DiscountMarkupTerms.ForAccumulatedSalesVolume);
	If GetFunctionalOption("UseLoyaltyCards") Then
		AvailableTermsOfService.Add(Enums.DiscountMarkupTerms.LoyaltyCardIsNotRegistered);
		AvailableTermsOfService.Add(Enums.DiscountMarkupTerms.ForLoyaltyCard);
	EndIf;
	AvailableTermsOfService.Add(Enums.DiscountMarkupTerms.ForPaymentForm);
	AvailableTermsOfService.Add(Enums.DiscountMarkupTerms.DuringSale);
	AvailableTermsOfService.Add(Enums.DiscountMarkupTerms.ForCustomerSBirthday);
	If GetFunctionalOption("UsePaymentSchedules") Then
		AvailableTermsOfService.Add(Enums.DiscountMarkupTerms.ForPaymentSchedule);
	EndIf;
	If GetFunctionalOption("UseUserGroups") Then
		AvailableTermsOfService.Add(Enums.DiscountMarkupTerms.LimitationByUserGroup);
	EndIf;
	If GetFunctionalOption("UsePartnersSegments") Then
		AvailableTermsOfService.Add(Enums.DiscountMarkupTerms.IncludeCustomerInSegment);
	EndIf;
	
	For Each ListItem In AvailableTermsOfService Do
		ListItem.Presentation = String(ListItem.Value);
	EndDo;
	
	If GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		
		RequestConditionFromExternalProcessing = New Query(
		"SELECT
		|	T.Ref AS Ref,
		|	T.Description AS Description,
		|	T.Information AS Information
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors AS T
		|WHERE
		|	T.Publication IN (VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.Used),
		|	                VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.DebugMode))
		|	AND Kind = &Kind
		|");
		
		RequestConditionFromExternalProcessing.Parameters.Insert("Kind", Enums.AdditionalReportsAndDataProcessorsKinds.CheckDiscountMarkupConditions);
		
		Selection = RequestConditionFromExternalProcessing.Execute().Select();
		
		While Selection.Next() Do
			AvailableTermsOfService.Add(Selection.Ref, Selection.Description);
		EndDo;
		
	EndIf;
	
	Return AvailableTermsOfService;
	
EndFunction


// Returns parameters for registering external processing for a discount (mark-up)
//
// Parameters:
//  Description - String - Name of the external processing.
//  Information - Structure - Information.
//
// Returns:
//  Structure - structure with properties:
//   * Kind - EnumRef.AdditionalReportsAndDataProcessorsKinds - Type of additional processing.
//   * Version - String - External processing version.
//   * Purpose - Array - The purpose of the processing.
//   * Description - String - Name of the processing method.
//   * SafeMode - Boolean - The sign of safe mode.
//   * Information - Structure - Information.
//   * SSLVersion - String - The required version of the BSP.
//   * Commands - ValueTable - The command is external processing.
//
Function RegistrationParametersExternalProcessingDiscountsMargins(Description, Information) Export
	
	RegistrationParameters = New Structure;
	
	RegistrationParameters.Insert("Kind", Enums.AdditionalReportsAndDataProcessorsKinds.DiscountMarkupCalculation);
	RegistrationParameters.Insert("Version", "1.0");
	RegistrationParameters.Insert("Purpose", New Array);
	RegistrationParameters.Insert("Description", Description);
	RegistrationParameters.Insert("SafeMode", True);
	RegistrationParameters.Insert("Information", Information);
	RegistrationParameters.Insert("SSLVersion", "2.1.2.1");
	
	RegistrationParameters.Insert("Commands", New ValueTable);
	
	Return RegistrationParameters;
	
EndFunction

// Returns the parameters of the register external processing conditions for the granting of the discount (markup).
//
// Parameters:
//  Description - String - Name of the external processing.
//  Information - Structure - Information.
//
// Returns:
//  Structure - structure with properties:
//   * Kind - EnumRef.AdditionalReportsAndDataProcessorsKinds - Type of additional processing.
//   * Version - String - External processing version.
//   * Purpose - Array - The purpose of the processing.
//   * Description - String - Name of the processing method.
//   * SafeMode - Boolean - The sign of safe mode.
//   * Information - Structure - Information.
//   * SSLVersion - String - The required version of the BSP.
//   * Commands - ValueTable - The command is external processing.
//
Function ParametersOfRegistrationOfExternalProcessingConditionsOfGrantingDiscountsMargins(Description, Information) Export
	
	RegistrationParameters = New Structure;
	
	RegistrationParameters.Insert("Kind", Enums.AdditionalReportsAndDataProcessorsKinds.CheckDiscountMarkupConditions);
	RegistrationParameters.Insert("Version", "1.0");
	RegistrationParameters.Insert("Purpose", New Array);
	RegistrationParameters.Insert("Description", Description);
	RegistrationParameters.Insert("SafeMode", True);
	RegistrationParameters.Insert("Information", Information);
	RegistrationParameters.Insert("SSLVersion", "2.1.2.1");
	
	RegistrationParameters.Insert("Commands", New ValueTable);
	
	Return RegistrationParameters;
	
EndFunction

#Region ProceduresForCalculatingDiscountsMarginsOnDocuments


// Calculates discounts for the document.
// Called from document forms.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  InputParameters - See DiscountsMarkupsFillingServer.NewParametersCalculate
//
// Returns:
//  Structure - structure with properties:
//   * DiscountTree - See CreateDiscountTree
//   * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//   * CalculationParameters - Structure - Structure of calculation parameters.
//
Function Calculate(Object, InputParameters) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(Object.Ref) = Type("DocumentRef.SalesOrder") Then
		
		CalculationResult2 = CalculateByCustomerOrder(Object, InputParameters);
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		
		CalculationResult2 = CalculateOnRequestForReturnOfGoodsFromClient(Object, InputParameters);
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.CommercialProposalForCustomer") Then
		
		CalculationResult2 = CalculateAccordingToCommercialOfferToClient(Object, InputParameters);
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.CashRegisterReceipt") Then
		
		CalculationResult2 = CalculateByReceiptCashRegister(Object, InputParameters);
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.CashRegisterReceiptReturn") Then

		CalculationResult2 = CalculateCashRegisterReturnByReceipt(Object, InputParameters);
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.CustomerInvoice") Then
		
		CalculationResult2 = CalculateForSaleOfGoodsServices(Object, InputParameters);
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.CustomerInvoiceServices") Then
		
		CalculationResult2 = CalculateActOfWorkPerformed(Object, InputParameters);
		
	EndIf;
	
	Return CalculationResult2;
	
EndFunction

// The procedure applies the discount calculation result to the document.
// Called from document forms.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  AppliedDiscounts - Structure - structure with properties:
//    * DiscountTree - ValueTree - Tree of discounts (markups).
//    * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//    * CalculationParameters - Structure - Structure of calculation parameters.
//  SalesInExcessOfOrder - Boolean - Implementation in excess of the order.
//
Procedure ApplyCalculationResult(Object, AppliedDiscounts, SalesInExcessOfOrder = False) Export
	
	If TypeOf(Object.Ref) = Type("DocumentRef.SalesOrder") Then
		
		ApplyCalculationResultToCustomerOrder(Object, AppliedDiscounts);
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		
		ApplyCalculationResultToReturnOfGoodsFromCustomer(Object, AppliedDiscounts);
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.CommercialProposalForCustomer") Then
		
		ApplyCalculationResultToCommercialOfferToClient(Object, AppliedDiscounts);
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.CashRegisterReceipt") Then
		
		ApplyCalculationResultToCashRegisterReceipt(Object, AppliedDiscounts);
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.CustomerInvoice") Then
		
		ApplyCalculationResultToSaleOfGoodsServices(Object, AppliedDiscounts, SalesInExcessOfOrder);
		
	ElsIf TypeOf(Object.Ref) = Type("DocumentRef.CustomerInvoiceServices") Then
		
		ApplyResultOfCalculationToActOfWorkPerformed(Object, AppliedDiscounts);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Function CalculateVATAmount(Sum, VATRate, Object) Export
	
	VATTaxation = Undefined;
	StandardProcessing = True;
	
	WhenDeterminingVATTaxation(Object, VATTaxation, StandardProcessing);
	
	If StandardProcessing Then
		VATTaxation = Object.VATTaxation;
	EndIf;
	
	Return VATAccountingERPClientServer.CalculateVATAmount(
		Sum,
		VATAccountingERPClientServer.ValueOfVATRate(VATRate),
		Object.PriceIncludesVAT,
		VATTaxation);
	
EndFunction

// Returns the available methods of providing discounts (extra charges)
//
// Returns:
//  Array - Available delivery methods.
//
Function AvailableDeliveryMethods() Export
	
	AvailableWaysToProvideDiscountMarkUps = New ValueList;
	AvailableWaysToGrantBonusPoints = New ValueList;
	
	WaysToProvideDiscountMargins = New Array;
	WaysToProvideDiscountMargins.Add(Enums.MethodsToProvideDiscountsMarkups.Percent);
	WaysToProvideDiscountMargins.Add(Enums.MethodsToProvideDiscountsMarkups.Sum);
	WaysToProvideDiscountMargins.Add(Enums.MethodsToProvideDiscountsMarkups.DiscountMarkupAsAmountForEachRow);
	WaysToProvideDiscountMargins.Add(Enums.MethodsToProvideDiscountsMarkups.Count);
	WaysToProvideDiscountMargins.Add(Enums.MethodsToProvideDiscountsMarkups.Gift);
	WaysToProvideDiscountMargins.Add(Enums.MethodsToProvideDiscountsMarkups.PriceKind);
	WaysToProvideDiscountMargins.Add(Enums.MethodsToProvideDiscountsMarkups.Message);
	WaysToProvideDiscountMargins.Add(Enums.MethodsToProvideDiscountsMarkups.RoundDocumentAmount);
	
	If GetFunctionalOption("UseLoyaltyCards") Then
		WaysToProvideDiscountMargins.Add(Enums.MethodsToProvideDiscountsMarkups.LoyaltyCard);
	EndIf;
	
	For Each MethodsOfProviding In WaysToProvideDiscountMargins Do
		AvailableWaysToProvideDiscountMarkUps.Add(MethodsOfProviding, String(MethodsOfProviding));
	EndDo;
	
	AvailableWaysToGrantBonusPoints.Add(
		Enums.MethodsToProvideDiscountsMarkups.Percent, NStr("vi = 'Điểm thưởng bằng phần trăm';
															|ru = 'Бонус процентом';
															|en = 'Bonus as a percentage'; fa = 'پاداش به صورت درصد';
															|it = 'Punti in percentuale';
															|pl = 'Bonus procentem';
															|tr = 'Bonus yüzdesi'"));
	AvailableWaysToGrantBonusPoints.Add(
		Enums.MethodsToProvideDiscountsMarkups.Sum, NStr("vi = 'Số tiền thưởng';
														|ru = 'Бонус суммой';
														|en = 'Bonus as an amount'; fa = 'Bonus as an amount';
														|it = 'Bonus come un importo';
														|pl = 'Bonus kwotą';
														|tr = 'İkramiye tutarı'"));
	
	If GetFunctionalOption("UseAdditionalReportsAndDataProcessors") Then
		
		RequestRenderingMethodsFromExternalTreatments = New Query(
		"SELECT
		|	T.Ref AS Ref,
		|	T.Description AS Description
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors AS T
		|WHERE
		|	T.Publication IN (VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.Used),
		|	                VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.DebugMode))
		|	AND Kind = &Kind
		|");
		
		RequestRenderingMethodsFromExternalTreatments.Parameters.Insert("Kind", Enums.AdditionalReportsAndDataProcessorsKinds.DiscountMarkupCalculation);
		
		Selection = RequestRenderingMethodsFromExternalTreatments.Execute().Select();
		
		While Selection.Next() Do
			
			ExternalDataProcessor = DiscountsMarkupsCached.ExternalDataProcessorObject(Selection.Ref);
			SetSafeMode(True);
			ApplicationMethod = ExternalDataProcessor.ApplicationMethod();
			SetSafeMode(False);
			
			If ApplicationMethod = Enums.DiscountMarkupApplicationMethods.GrantBonusPoints Then
				AvailableWaysToGrantBonusPoints.Add(Selection.Ref, Selection.Description);
			Else
				AvailableWaysToProvideDiscountMarkUps.Add(Selection.Ref, Selection.Description);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	MethodsOfProviding_ = New Structure;
	MethodsOfProviding_.Insert("DiscountsMarkups", AvailableWaysToProvideDiscountMarkUps);
	If GetFunctionalOption("UseLoyaltyPrograms") Then
		MethodsOfProviding_.Insert("BonusPoints", AvailableWaysToGrantBonusPoints);
	EndIf;
	
	Return MethodsOfProviding_;
	
EndFunction

// Returns the index of the image for the discount.
//
// Parameters:
//  TreeRow - ValueTreeRow - a string of the value tree.
//
// Returns:
//  Number - index of the image.
//
Function GetImageIndexForGroup(TreeRow) Export
	
	IndexOf = 0;
	If TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Max Then
		IndexOf = 8;
	ElsIf TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Min Then
		IndexOf = 16;
	ElsIf TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Addition Then
		IndexOf = 0;
	ElsIf TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Multiplication Then
		IndexOf = 4;
	ElsIf TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Exclusion Then
		IndexOf = 12;
	EndIf;
	
	If TreeRow.DeletionMark Then
		IndexOf = IndexOf + 3;
	EndIf;
	
	Return IndexOf;
	
EndFunction

// Returns the index of the image for the discount.
//
// Parameters:
//  TreeRow - ValueTreeRow - a string of the value tree.
//
// Returns:
//  Number - index of the image.
//
Function GetImageIndexForDiscount(TreeRow) Export
	
	IndexOf = 0;
	If TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Percent Then
		If TreeRow.DiscountMarkupValue < 0 Then
			IndexOf = 32;
		Else
			IndexOf = 28;
		EndIf;
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Count Then
		IndexOf = 36;
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Gift Then
		IndexOf = 36;
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Sum Then
		If TreeRow.DiscountMarkupValue < 0 Then
			IndexOf = 40;
		Else
			IndexOf = 44;
		EndIf;
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.RoundDocumentAmount Then
		If TreeRow.DiscountMarkupValue < 0 Then
			IndexOf = 40;
		Else
			IndexOf = 44;
		EndIf;
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.DiscountMarkupAsAmountForEachRow Then
		If TreeRow.DiscountMarkupValue < 0 Then
			IndexOf = 40;
		Else
			IndexOf = 44;
		EndIf;
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.PriceKind Then
		IndexOf = 48;
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Message Then
		IndexOf = 52;
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.LoyaltyCard Then
		IndexOf = 52;
	ElsIf TypeOf(TreeRow.MethodsOfProviding) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		IndexOf = 56;
	EndIf;
	
	If TreeRow.DeletionMark Then
		IndexOf = IndexOf + 3;
	EndIf;
	
	Return IndexOf;
	
EndFunction

// Update cached queries for all Catalog items.
Procedure UpdateCachedRequestsDiscountsMargins() Export
	Query = New Query;
	Query.Text = RequestTextForUpdatingCachedRequestsDiscountsMargins();
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If Not RegistrationRequired(Selection.Ref) Then
			Continue;
		EndIf;
		
		CatalogObject = Selection.Ref.GetObject();//CatalogObject.DiscountsMarkups
		
		UpdateCachedRequest(CatalogObject);
		
		Try
			CatalogObject.Write();
		Except
			MessageText = NStr("vi = 'Không thể xử lý đối tượng: %Object% theo nguyên nhân: %Cause%';
								|ru = 'Не удалось обработать объект: %Object% по причине: %Cause%';
								|en = 'Cannot process object %Object%. Reason: %Cause%'; fa = 'Cannot process object %Object%. Reason: %Cause%';
								|it = 'Impossibile elaborare l''oggetto: %Object% motivo: %Cause%';
								|pl = 'Nie udało się przetworzyć obiekt: %Object% z powodu: %Cause%';
								|tr = '%Cause% nedeniyle nesne: %Object% işlenemedi'");
			MessageText = StrReplace(MessageText, "%Object%", Selection.Ref);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorDescription()));
			WriteLogEvent(NStr("vi = 'Cập nhật truy vấn đã lưu trong bộ nhớ cache';
								|ru = 'Обновление кешированных запросов';
								|en = 'Update cached requests'; fa = 'Update cached requests';
								|it = 'Aggiornamento delle richieste di cache';
								|pl = 'Aktualizacja zapytań buforowanych';
								|tr = 'Önbelleğe alınmış sorguları güncelleme'", Common.DefaultLanguageCode()),
									EventLogLevel.Warning,
									Selection.Ref.Metadata(),
									Selection.Ref,
									MessageText);
		EndTry;
		
	EndDo;
	
EndProcedure

// Update cached queries for all Catalog items.
Procedure UpdateCachedRequestsTermsOfDiscountsAndMargins() Export
	Query = New Query;
	Query.Text = RequestTextForUpdatingCachedRequestsTermsOfDiscountsAndMargins();
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If Not RegistrationRequired(Selection.Ref) Then
			Continue;
		EndIf;
		
		CatalogObject = Selection.Ref.GetObject();//CatalogObject.DiscountMarkupTerms
		
		UpdateCachedRequest(CatalogObject);
		
		Try
			CatalogObject.Write();
		Except
			MessageText = NStr("vi = 'Không thể xử lý đối tượng: %Object% theo nguyên nhân: %Cause%';
								|ru = 'Не удалось обработать объект: %Object% по причине: %Cause%';
								|en = 'Cannot process object %Object%. Reason: %Cause%'; fa = 'Cannot process object %Object%. Reason: %Cause%';
								|it = 'Impossibile elaborare l''oggetto: %Object% motivo: %Cause%';
								|pl = 'Nie udało się przetworzyć obiekt: %Object% z powodu: %Cause%';
								|tr = '%Cause% nedeniyle nesne: %Object% işlenemedi'");
			MessageText = StrReplace(MessageText, "%Object%", Selection.Ref);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorDescription()));
			WriteLogEvent(NStr("vi = 'Cập nhật truy vấn đã lưu trong bộ nhớ cache';
								|ru = 'Обновление кешированных запросов';
								|en = 'Update cached requests'; fa = 'Update cached requests';
								|it = 'Aggiornamento delle richieste di cache';
								|pl = 'Aktualizacja zapytań buforowanych';
								|tr = 'Önbelleğe alınmış sorguları güncelleme'", Common.DefaultLanguageCode()),
									EventLogLevel.Warning,
									Selection.Ref.Metadata(),
									Selection.Ref,
									MessageText);
		EndTry;
		
	EndDo;
	
EndProcedure

// Clear links to external processing for all Catalog elements.
// 
// Parameters:
//  MarkForDeletion_ - Boolean - Set the specified mark for deletion
Procedure ClearDiscountsMarkupsFromExternalDataProcessors(MarkForDeletion_ = True) Export
	Query = New Query;
	Query.Text = "SELECT
	|	DiscountsMarkups.Ref AS Ref
	|FROM
	|	Catalog.DiscountsMarkups AS DiscountsMarkups
	|WHERE
	|	NOT DiscountsMarkups.IsFolder
	|	AND VALUETYPE(DiscountsMarkups.MethodsOfProviding) = TYPE(Catalog.AdditionalReportsAndDataProcessors)";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		CatalogObject = Selection.Ref.GetObject();//CatalogObject.DiscountsMarkups
		CatalogObject.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Percent;
		CatalogObject.DeletionMark = MarkForDeletion_;
		
		Try
			CatalogObject.Write();
		Except
			MessageText = NStr("vi = 'Không thể xử lý đối tượng: %Object% do nguyên nhân: %Cause%';
								|ru = 'Не удалось обработать объект: %Object% по причине: %Cause%';
								|en = 'Cannot process object %Object%. Reason: %Cause%'; fa = 'Cannot process object %Object%. Reason: %Cause%';
								|it = 'Impossibile elaborare l''oggetto: %Object% motivo: %Cause%';
								|pl = 'Nie udało się przetworzyć obiekt: %Object% z powodu: %Cause%';
								|tr = '%Cause% nedeniyle nesne: %Object% işlenemedi'");
			MessageText = StrReplace(MessageText, "%Object%", Selection.Ref);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorDescription()));
			WriteLogEvent(NStr("vi = 'Xóa khỏi bộ xử lý ngoài';
								|ru = 'Очистка от внешних обработок';
								|en = 'Clear from external data processors'; fa = 'Clear from external data processors';
								|it = 'Очистка от внешних обработок';
								|pl = 'Clear from external data processors';
								|tr = 'Harici işlemelerden temizleme'", Common.DefaultLanguageCode()),
									EventLogLevel.Warning,
									Selection.Ref.Metadata(),
									Selection.Ref,
									MessageText);
		EndTry;
		
	EndDo;
	
EndProcedure

// Clear links to external processing for all Catalog elements.
// 
// Parameters:
//  MarkForDeletion_ - Boolean - Set the specified mark for deletion
Procedure ClearDiscountMarkupTermsFromExternalDataProcessors(MarkForDeletion_ = True) Export
	Query = New Query;
	Query.Text = "SELECT
	|	DiscountMarkupTerms.Ref AS Ref
	|FROM
	|	Catalog.DiscountMarkupTerms AS DiscountMarkupTerms
	|WHERE
	|	NOT DiscountMarkupTerms.IsFolder
	|	AND VALUETYPE(DiscountMarkupTerms.DiscountMarkupCondition) = TYPE(Catalog.AdditionalReportsAndDataProcessors)";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		CatalogObject = Selection.Ref.GetObject();//CatalogObject.DiscountMarkupTerms
		CatalogObject.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ExternalDataProcessor;
		CatalogObject.DeletionMark = MarkForDeletion_;
		
		Try
			CatalogObject.Write();
		Except
			MessageText = NStr("vi = 'Không thể xử lý đối tượng: %Object% do nguyên nhân: %Cause%';
								|ru = 'Не удалось обработать объект: %Object% по причине: %Cause%';
								|en = 'Cannot process object %Object%. Reason: %Cause%'; fa = 'Cannot process object %Object%. Reason: %Cause%';
								|it = 'Impossibile elaborare l''oggetto: %Object% motivo: %Cause%';
								|pl = 'Nie udało się przetworzyć obiekt: %Object% z powodu: %Cause%';
								|tr = '%Cause% nedeniyle nesne: %Object% işlenemedi'");
			MessageText = StrReplace(MessageText, "%Object%", Selection.Ref);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorDescription()));
			WriteLogEvent(NStr("vi = 'Xóa khỏi bộ xử lý ngoài';
								|ru = 'Очистка от внешних обработок';
								|en = 'Clear from external data processors'; fa = 'Clear from external data processors';
								|it = 'Очистка от внешних обработок';
								|pl = 'Clear from external data processors';
								|tr = 'Harici işlemelerden temizleme'", Common.DefaultLanguageCode()),
									EventLogLevel.Warning,
									Selection.Ref.Metadata(),
									Selection.Ref,
									MessageText);
		EndTry;
		
	EndDo;
	
EndProcedure


#EndRegion

#Region Private

// Determines the use of a discount (mark-up)
//
// Parameters:
//  DiscountMarkup  - CatalogRef.DiscountsMarkups - discount (mark-up) for which usage is determined
//  ValidityDate   - Date - the date on which usage is determined.
//
// Returns:
//	Structure - contains the following fields:
//		* ValidInWarehouses 					- Number - the number of warehouses that have a discount (mark-up).
//		* TotalWarehouses 						- Number - the number of warehouses for which 
//															the discount (mark-up) setting was performed.
//		* ValidInStandardAgreements 			- Number - the number of standard agreements that have 
//															a discount (mark-up).
//		* ValidInIndividualAgreements 	- Number - the number of individual agreements that are subject
//                                                        	to a discount (mark-up).
//		* TotalAgreements 					- Number - the number of agreements for which 
//															the discount (mark-up) setting was performed.
//		* ValidInLoyaltyCards 			- Number - the number of types of loyalty cards that have 
//															a discount (mark-up).
//		* TotalInLoyaltyCards 				- Number - the number of types of loyalty cards for which the 
//															discount discount (mark-up) was performed.
//		* ValidInAllWarehouses 				- Boolean - indicates that the discount (mark-up) is valid for all warehouses
//		* StartDateOfUnconditionalAction 		- Date - the start date of the General discount (mark-up).
//		* ExpirationDateOfUnconditionalValidity 	- Date - the end date of the General discount (mark-up), an empty date
//                                                     if the action is indefinite.
//
Function UsingMarkUpDiscount(DiscountMarkup, ValidityDate) Export
	
	If DiscountMarkup = Undefined Then
		Return Undefined;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ValidInWarehouses", 0);
	Result.Insert("TotalWarehouses", 0);
	Result.Insert("ValidInStandardAgreements", 0);
	Result.Insert("TotalInStandardAgreements", 0);
	Result.Insert("ValidInIndividualAgreements", 0);
	Result.Insert("TotalInIndividualAgreements", 0);
	Result.Insert("ValidInLoyaltyCards", 0);
	Result.Insert("TotalInLoyaltyCards", 0);
	Result.Insert("ValidInAllWarehouses", False);
	Result.Insert("StartDateOfUnconditionalAction", Date(1, 1, 1));
	Result.Insert("ExpirationDateOfUnconditionalValidity", Date(1, 1, 1));
	
	FillPropertyValues(Result, SettingsValueCached.NumberOfSourcesOfDiscountsMargins());
	
	Query = New Query(
	"SELECT ALLOWED DISTINCT
	|	TheEffectOfDiscountsMarkupsASliceOfTheLast.Source AS Source,
	|	TheEffectOfDiscountsMarkupsASliceOfTheLast.Status
	|INTO Sources
	|FROM
	|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&CurrentDate, DiscountMarkup = &DiscountMarkup) AS TheEffectOfDiscountsMarkupsASliceOfTheLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CASE
	|		WHEN VALUETYPE(Sources.Source) = TYPE(Catalog.Warehouses)
	|			THEN ""ValidInWarehouses""
	|		WHEN VALUETYPE(Sources.Source) = TYPE(Catalog.LoyaltyCardKinds)
	|			THEN ""ValidByLoyaltyCardType""
	|		WHEN &TextOnAgreements THEN """"
	|	END AS WhereApplied,
	|	MAX(CASE
	|			WHEN Sources.Source = VALUE(Catalog.Warehouses.EmptyRef)
	|					AND Sources.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS ValidInEmptyWarehouse,
	|	SUM(CASE
	|			WHEN Sources.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
	|					AND Sources.Source <> VALUE(Catalog.Warehouses.EmptyRef)
	|				THEN 1
	|			ELSE 0
	|		END) AS OperatesOnSources
	|FROM
	|	Sources AS Sources
	|
	|GROUP BY
	|	CASE
	|		WHEN VALUETYPE(Sources.Source) = TYPE(Catalog.Warehouses)
	|			THEN ""ValidInWarehouses""
	|		WHEN VALUETYPE(Sources.Source) = TYPE(Catalog.LoyaltyCardKinds)
	|			THEN ""ValidByLoyaltyCardType""
	|		WHEN &TextOnAgreements THEN """"
	|	END");
	
	If AccessRight("Read", Metadata.Catalogs.TermsOfSale) Then
		
		TextOnAgreements ="
		|		WHEN VALUETYPE(Sources.Source) = TYPE(Catalog.TermsOfSale)
		|			THEN CASE
		|					WHEN CAST(Sources.Source AS Catalog.TermsOfSale).Standard_
		|						THEN ""OperatesUnderStandardAgreementsWithClients""
		|					ELSE ""OperatesUnderIndividualAgreementsWithClients""
		|				END";
		
	Else 
		TextOnAgreements = "";
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "WHEN &TextOnAgreements THEN """"", TextOnAgreements);

	Query.SetParameter("CurrentDate", ValidityDate);
	Query.SetParameter("DiscountMarkup", DiscountMarkup);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.WhereApplied = "ValidInWarehouses" Then
			
			If GetFunctionalOption("UseSeveralWarehouses") Then
				Result.ValidInWarehouses  = Selection.OperatesOnSources;
			EndIf;
			Result.ValidInAllWarehouses = Selection.ValidInEmptyWarehouse;
			
		ElsIf Selection.WhereApplied = "ValidByLoyaltyCardType" 
			And GetFunctionalOption("UseLoyaltyCards") Then
		
			Result.ValidInLoyaltyCards = Selection.OperatesOnSources;
			
		ElsIf Selection.WhereApplied = "OperatesUnderStandardAgreementsWithClients" 
			And GetFunctionalOption("UseStandardTermsOfSalesWithCustomers") Then
		
			Result.ValidInStandardAgreements = Selection.OperatesOnSources;
			
		ElsIf Selection.WhereApplied = "OperatesUnderIndividualAgreementsWithClients" 
			And GetFunctionalOption("UseCustomerTermsOfSales") Then
		
			Result.ValidInIndividualAgreements = Selection.OperatesOnSources;
		
		EndIf;
		
	EndDo;
	
	If Result.ValidInAllWarehouses Then
		
		Query.Text = "
		|SELECT 
		|	TheEffectOfDiscountsMarkupsASliceOfTheLast.Period AS Period
		|INTO ValidOnDate
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(
		|			&CurrentDate,
		|			DiscountMarkup = &DiscountMarkup
		|				AND Status = VALUE(Enum.DiscountValidityStatuses.Valid)
		|				AND Source = VALUE(Catalog.Warehouses.EmptyRef)) AS TheEffectOfDiscountsMarkupsASliceOfTheLast
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT 
		|	MIN(ValidityOfDiscountsMarkups.Period) AS Period
		|INTO ValidTo
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups AS ValidityOfDiscountsMarkups
		|WHERE
		|	ValidityOfDiscountsMarkups.Period > &CurrentDate
		|	AND ValidityOfDiscountsMarkups.Source = VALUE(Catalog.Warehouses.EmptyRef)
		|	AND ValidityOfDiscountsMarkups.Status = VALUE(Enum.DiscountValidityStatuses.NotValid)
		|	AND ValidityOfDiscountsMarkups.DiscountMarkup = &DiscountMarkup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ValidOnDate.Period AS ValidOnDate,
		|	ISNULL(DATEADD(ValidTo.Period, DAY, -1), DATETIME(1, 1, 1)) AS ValidTo
		|FROM
		|	ValidOnDate AS ValidOnDate
		|	LEFT JOIN ValidTo AS ValidTo
		|	ON (TRUE)";
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			Result.ExpirationDateOfUnconditionalValidity = Selection.ValidTo;
			Result.StartDateOfUnconditionalAction    = Selection.ValidOnDate;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Generates information lines on the use of discounts (mark-UPS) in the context of types of action sources.
//
// Parameters:
//  Form  - ClientApplicationForm - a form for filling in string variables containing 
//                                        information about the number of discounts (markups).
//  UsingMarkUpDiscount          - See UsingMarkUpDiscount
//
Procedure GenerateInformationAboutNumberOfDiscountsUsed(Form, UsingMarkUpDiscount) Export

	TitleTemplate1          = NStr("vi = '%1 từ %2';
									|ru = '%1 из %2';
									|en = '%1 out of %2'; fa = '%1 out of %2';
									|it = '%1 da %2';
									|pl = '%1 z %2';
									|tr = '%2''dan %1'");
	AgreementInformation         = "";
	InformationWarehouses             = "";
	InformationTypesOfLoyaltyCards = "";
	
	If Not UsingMarkUpDiscount = Undefined Then
		
		If UsingMarkUpDiscount.TotalInStandardAgreements > 0 Then
			
			InformationModelAgreements = StrTemplate(TitleTemplate1, 
				                                    UsingMarkUpDiscount.ValidInStandardAgreements,
				                                    UsingMarkUpDiscount.TotalInStandardAgreements);
		EndIf;
			
		If UsingMarkUpDiscount.TotalInIndividualAgreements > 0 Then
			
			InformationIndividualAgreements = StrTemplate(TitleTemplate1, 
				                                           UsingMarkUpDiscount.ValidInIndividualAgreements,
				                                           UsingMarkUpDiscount.TotalInIndividualAgreements);
		EndIf;
		
		If UsingMarkUpDiscount.TotalWarehouses > 0 Then
			
			InformationWarehouses = StrTemplate(TitleTemplate1, 
				                         UsingMarkUpDiscount.ValidInWarehouses,
				                         UsingMarkUpDiscount.TotalWarehouses);
		EndIf;
		
		If UsingMarkUpDiscount.TotalInLoyaltyCards > 0 Then
			
			InformationTypesOfLoyaltyCards = 
			      StrTemplate(TitleTemplate1, 
			                UsingMarkUpDiscount.ValidInLoyaltyCards,
			                UsingMarkUpDiscount.TotalInLoyaltyCards);
		EndIf;
		
	EndIf;
		
	Form.InformationNumberOfDiscountsIndividualAgreements = InformationIndividualAgreements;
	Form.InformationDiscountNumberStandardAgreements        = InformationModelAgreements;
	Form.InformationDiscountNumberWarehouses                   = InformationWarehouses;
	Form.InformationNumberOfLoyaltyCardDiscounts          = InformationTypesOfLoyaltyCards;

EndProcedure

// Generates and sets an information label about the use of discounts(mark-UPS)
//
// Parameters:
//  InformationOnDiscountValidity  - String - String of information.
//  UsingMarkUpDiscount - Structure - contains information about using the discount (mark-up). For more information about
//                                           the structure fields, see the description of the function using bid mark-Up.
//  AdditionalCommand          - String - name of the additional command to be output.
//  DisplayExplanationOfGeneralStatus - Boolean - indicates whether information explaining the General status should be displayed.
//
Procedure CreateInformationLabelUsingDiscountsMargins(InformationOnDiscountValidity,
	                                                                  UsingMarkUpDiscount,
	                                                                  AdditionalCommand = Undefined,
	                                                                  DisplayExplanationOfGeneralStatus = True) Export
	
	If UsingMarkUpDiscount = Undefined Then
		InformationOnDiscountValidity = "";
		If AdditionalCommand = "ConfigureDiscounts" Then
			InformationOnDiscountValidity = New FormattedString(NStr("vi = 'Tùy chỉnh chiết khấu (phụ thu)';
																	|ru = 'Настроить скидки (наценки)';
																	|en = 'Set up discounts (markups)'; fa = 'Set up discounts (markups)';
																	|it = 'Impostare gli sconti (markup)';
																	|pl = 'Dostosuj zniżki (marże)';
																	|tr = 'İndirim/zam ayarla'"),, StyleColors.HyperlinkColor,,"ConfigureDiscounts");
		EndIf;
		Return;
	EndIf;
	
	UseSeveralWarehouses                   = GetFunctionalOption("UseSeveralWarehouses");
	UseStandardTermsOfSalesWithCustomers        = GetFunctionalOption("UseStandardTermsOfSalesWithCustomers");
	UseCustomerTermsOfSales = GetFunctionalOption("UseCustomerTermsOfSales");
	UseLoyaltyCards                    = GetFunctionalOption("UseLoyaltyCards");
	UseSimplifiedMode =   Not UseSeveralWarehouses
	                              And Not UseStandardTermsOfSalesWithCustomers
	                              And Not UseCustomerTermsOfSales
	                              And Not UseLoyaltyCards;
	
	LabelText = "";
	
	If (UsingMarkUpDiscount.ValidInWarehouses = 0) 
		And (UsingMarkUpDiscount.ValidInLoyaltyCards = 0) 
		And (UsingMarkUpDiscount.ValidInStandardAgreements = 0)
		And (UsingMarkUpDiscount.ValidInIndividualAgreements = 0)
		And Not UsingMarkUpDiscount.ValidInAllWarehouses  Then
		
		LabelText = LabelText + " " + NStr("vi = 'Không được cung cấp';
											|ru = 'Не предоставляется';
											|en = 'Not provided'; fa = 'Not provided';
											|it = 'Non viene fornito';
											|pl = 'Nie jest udostępniane';
											|tr = 'Sağlanmıyor'");
		
	Else
		
		LabelText = LabelText + " " + NStr("vi = 'Được phép';
											|ru = 'Предоставляется';
											|en = 'Applied in'; fa = 'Applied in';
											|it = 'Fornisce';
											|pl = 'Udostępniane';
											|tr = 'Sağlanıyor'");
		CommaRequired_ = False;
		
		If Not UsingMarkUpDiscount.ValidInAllWarehouses Then
			
			LabelText = LabelText + " ";
			
			If UsingMarkUpDiscount.ValidInWarehouses > 0 Then
				
				LabelText = LabelText + NStr("vi = 'người nhận kho';
											|ru = 'получателям складов';
											|en = 'warehouse recipients'; fa = 'warehouse recipients';
											|it = 'ai destinatari dei magazzini';
											|pl = 'odbiorcom magazynu';
											|tr = 'ambar alıcılarına'") + " (" + UsingMarkUpDiscount.ValidInWarehouses + ")";
				CommaRequired_ = True;
				
			EndIf;
			
			If UsingMarkUpDiscount.ValidInLoyaltyCards > 0 Then
				
				LabelText = ?(CommaRequired_,LabelText + ", ", LabelText);
				LabelText = LabelText + NStr("vi = 'chủ thẻ khách hàng thân thiết';
											|ru = 'держателям карт лояльности';
											|en = 'loyalty card holders'; fa = 'loyalty card holders';
											|it = 'ai titolari delle carte fedeltà';
											|pl = 'dla posiadaczy kart lojalnościowych';
											|tr = 'sadakat kartı sahiplerine'") + " (" + UsingMarkUpDiscount.ValidInLoyaltyCards + ")";
				CommaRequired_ = True;
				
			EndIf;
			
			If UsingMarkUpDiscount.ValidInStandardAgreements > 0 Then
				
				LabelText = ?(CommaRequired_,LabelText + ", ", LabelText);
				LabelText = LabelText + NStr("vi = 'người tham gia thỏa thuận mô hình';
											|ru = 'участникам типовых соглашений';
											|en = 'standard terms'; fa = 'standard terms';
											|it = 'ai partecipanti degli accordi tipo';
											|pl = 'uczestnikom typowych umów';
											|tr = 'standart sözleşme katılımcılarına'") + " (" + UsingMarkUpDiscount.ValidInStandardAgreements + ")";
				CommaRequired_ = True;
				
			EndIf;
			
			If UsingMarkUpDiscount.ValidInIndividualAgreements > 0 Then
				
				LabelText = ?(CommaRequired_,LabelText + ", ", LabelText);
				LabelText = LabelText + NStr("vi = 'các bên tham gia thỏa thuận cá nhân';
											|ru = 'участникам индивидуальных соглашений';
											|en = 'individual terms'; fa = 'individual terms';
											|it = 'ai partecipanti degli accordi individuali';
											|pl = 'uczestnikom indywidualnych umów';
											|tr = 'bireysel sözleşme katılımcılarına'") + " (" + UsingMarkUpDiscount.ValidInIndividualAgreements + ")";
				CommaRequired_ = True;
				
			EndIf;
			
		Else
			
			LabelText = NStr("vi = 'Có sẵn cho tất cả khách hàng';
							|ru = 'Предоставляется всем клиентам';
							|en = 'Provided to all customers'; fa = 'Provided to all customers';
							|it = 'Viene fornito ai tutti i clienti';
							|pl = 'Dostępny dla wszystkich klientów';
							|tr = 'Tüm müşterilere sağlanıyor'");
			
			PeriodTemplate = NStr("vi = '(từ %1 %2 %3)';
									|ru = '(с %1 %2 %3)';
									|en = '(with %1 %2 %3)'; fa = '(with %1 %2 %3)';
									|it = '(dal %1 %2 %3)';
									|pl = '(z %1 %2 %3)';
									|tr = '(%1 %2 %3 ile)'");
			LabelText = LabelText + " " + StrTemplate(
			              PeriodTemplate,
			              Format(UsingMarkUpDiscount.StartDateOfUnconditionalAction, "DLF=DD"),
			              ?(UsingMarkUpDiscount.ExpirationDateOfUnconditionalValidity = Date(1, 1, 1),NStr("vi = 'và';
																											|ru = 'и';
																											|en = 'and'; fa = 'و';
																											|it = 'e';
																											|pl = 'oraz';
																											|tr = 've'"),NStr("vi = 'đến';
																																|ru = 'по';
																																|en = 'to'; fa = 'تا';
																																|it = 'al';
																																|pl = 'do';
																																|tr = 'göre'")),
			              ?(UsingMarkUpDiscount.ExpirationDateOfUnconditionalValidity = Date(1, 1, 1),
			                 NStr("vi = 'không giới hạn';
									|ru = 'бессрочно';
									|en = 'permanent'; fa = 'permanent';
									|it = 'a tempo indefinito';
									|pl = 'bezterminowo';
									|tr = 'süresiz'"),
			                 Format(UsingMarkUpDiscount.ExpirationDateOfUnconditionalValidity, "DLF=DD")));
			
			If DisplayExplanationOfGeneralStatus 
				And (UsingMarkUpDiscount.TotalWarehouses > 0 
				Or UsingMarkUpDiscount.TotalInLoyaltyCards > 0
				Or UsingMarkUpDiscount.ValidInStandardAgreements > 0
				Or UsingMarkUpDiscount.ValidInIndividualAgreements > 0)  Then
				
				If AdditionalCommand = "ConfigureDiscounts" Then
					ExplanationText = NStr("vi = 'Trong thời gian hiệu lực của trạng thái chung, các cài đặt được thực hiện trong biểu mẫu này không liên quan.';
											|ru = 'В период действия общего статуса настройки, сделанные в данной форме не актуальны.';
											|en = 'The settings in this form are not relevant when the overall status is valid.'; fa = 'The settings in this form are not relevant when the overall status is valid.';
											|it = 'Nel periodo di validità dello stato generale, le impostazioni predefinite in questo modulo non sono rilevanti.';
											|pl = 'W okresie obowiązywania ogólnego statusu ustawienia wprowadzone w tym formularzu nie są istotne.';
											|tr = 'Bu form üzerinde yapılan ayarlar genel durum süresi boyunca geçerli değildir.'");
				Else
					ExplanationText = NStr("vi = 'Trong thời gian hiệu lực của tình trạng chung, các giải thích rõ ràng ở trên không liên quan.';
											|ru = 'В период действия общего статуса вышеуказанные уточнения не актуальны.';
											|en = 'The clarifications mentioned above are not relevant when the overall status is valid.'; fa = 'The clarifications mentioned above are not relevant when the overall status is valid.';
											|it = 'Nel periodo di validità dello stato generale, i suddetti chiarimenti non sono rilevanti.';
											|pl = 'W okresie obowiązywania ogólnego statusu powyższe wyjaśnienia nie są istotne.';
											|tr = 'Genel durumun geçerliliği döneminde, yukarıdaki iyileştirmeler geçerli değildir.'");
				EndIf;
				
				LabelText = LabelText + "." + Chars.LF + ExplanationText;
				
			EndIf;
		
		EndIf;
		
	EndIf;
	
	StringInformation_  = New FormattedString(LabelText + "  ",, StyleColors.FieldTextColor);
	
	If AdditionalCommand <> Undefined
		And AccessRight("Update", Metadata.InformationRegisters.ValidityOfDiscountsMarkups) Then
		
		If AdditionalCommand = "Change" Then
			LineEdit = New FormattedString(NStr("vi = 'Thay đổi';
												|ru = 'Изменить';
												|en = 'Change'; fa = 'تغییر';
												|it = 'Modificare';
												|pl = 'Zmień';
												|tr = 'Değiştir'"),, StyleColors.HyperlinkColor,,"Change");
		ElsIf AdditionalCommand = "ConfigureDiscounts" Then
			LineEdit = New FormattedString(NStr("vi = 'Tùy chỉnh chiết khấu (phụ thu)';
												|ru = 'Настроить скидки (наценки)';
												|en = 'Set up discounts (markups)'; fa = 'Set up discounts (markups)';
												|it = 'Impostare gli sconti (markup)';
												|pl = 'Dostosuj zniżki (marże)';
												|tr = 'İndirim/zam ayarla'"),, StyleColors.HyperlinkColor,,"ConfigureDiscounts");
		ElsIf AdditionalCommand = "ChangeOverallStatus" Then
			LineEdit = New FormattedString(NStr("vi = 'Thay đổi trạng thái chung';
												|ru = 'Изменить общий статус';
												|en = 'Change overall status'; fa = 'Change overall status';
												|it = 'Modificare lo stato generale';
												|pl = 'Zmienić ogólny status';
												|tr = 'Genel durumu değiştir'"),, StyleColors.HyperlinkColor,,"ChangeOverallStatus");
		Else
			LineEdit = "";
		EndIf;
		
		InformationOnDiscountValidity = New FormattedString(StringInformation_, LineEdit);
	Else
		InformationOnDiscountValidity = StringInformation_;
	EndIf;

EndProcedure

// Generates information about the number of active discounts (markups) for the action source.
//
// Parameters:
//  Source  - CatalogRef.Warehouses, CatalogRef.LoyaltyCardKinds, CatalogRef.TermsOfSale -
//              the source of the discount.
//  SliceDate  - Date - the date on which information about the validity of discounts is received.
//
// Returns:
//   String   - in the format "Quantity acts from quantity".
//
Function InformationOnDiscountNumber(Source, SliceDate) Export
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(Source) Then
		Return "";
	EndIf;
	
	Total     = 0;
	Valid = 0;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	SUM(1) AS NumberOfValidDiscounts
	|INTO CurrentDiscounts
	|FROM
	|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&SliceDate, Source = &Source) AS TheEffectOfDiscountsMarkupsASliceOfTheLast
	|WHERE
	|	TheEffectOfDiscountsMarkupsASliceOfTheLast.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(1) AS NumberOfDiscountsTotal
	|INTO TotalDiscounts
	|FROM
	|	Catalog.DiscountsMarkups AS DiscountsMarkups
	|WHERE
	|	NOT DiscountsMarkups.IsFolder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TotalDiscounts.NumberOfDiscountsTotal AS Total,
	|	ISNULL(CurrentDiscounts.NumberOfValidDiscounts, 0) AS Valid
	|FROM
	|	TotalDiscounts AS TotalDiscounts
	|		LEFT JOIN CurrentDiscounts AS CurrentDiscounts
	|		ON (TRUE)";
	
	Query.SetParameter("Source", Source);
	Query.SetParameter("SliceDate", SliceDate);
	
	Selection = Query.Execute().Select();

	If Selection.Next() Then
		Total     = Selection.Total;
		Valid = Selection.Valid;
	EndIf;
	
	If Total = 0 Then
		Return "";
	EndIf;
	
	Return StrTemplate(NStr("vi = '%1 từ %2';
							|ru = '%1 из %2';
							|en = '%1 out of %2'; fa = '%1 out of %2';
							|it = '%1 da %2';
							|pl = '%1 z %2';
							|tr = '%2''dan %1'"),Valid, Total);

EndFunction 

// Gets the values of functional options required in various forms of discounts (mark-UPS).
//
// Returns:
//   Structure   - contains the values of the required functional options.
//
Function StructureOfDiscountSourcesAccordingToFederalLaw() Export
	
	StructureToReturn = New Structure;
	
	StructureToReturn.Insert("UseLoyaltyCards", GetFunctionalOption("UseLoyaltyCards"));
	StructureToReturn.Insert("UseLoyaltyPrograms", GetFunctionalOption("UseLoyaltyPrograms"));
	StructureToReturn.Insert("UseSeveralWarehouses", GetFunctionalOption("UseSeveralWarehouses"));
	StructureToReturn.Insert("ToUseTermsOfSales", GetFunctionalOption("ToUseTermsOfSales"));
	
	Return StructureToReturn;
	
EndFunction

// Parameters:
// 	TableDiscountsMarkups - See ValidityOfDiscountsMarkupsSource
//
Procedure BuildDiscountMarkUpTreeRecursively(DiscountTree, TableDiscountsMarkups)
	
	For Each TreeRow In DiscountTree.Rows Do
		
		If TreeRow.IsFolder Then
			
			BuildDiscountMarkUpTreeRecursively(TreeRow, TableDiscountsMarkups);
			
			TreeRow.PictureIndex = GetImageIndexForGroup(TreeRow);
			
		Else
			
			TreeRow.PictureIndex = GetImageIndexForDiscount(TreeRow);
			
			Filter = New Structure;
			Filter.Insert("DiscountMarkup", TreeRow.Ref);
			FoundRows = TableDiscountsMarkups.FindRows(Filter);
			If FoundRows.Count() > 0 Then
				TreeRow.Status = FoundRows[0].Status;
				TreeRow.StartDate = FoundRows[0].StartDate;
				TreeRow.EndDate = FoundRows[0].EndDate;
			Else
				TreeRow.Status = Enums.DiscountValidityStatuses.NotValid;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Builds a tree of discounts (markups) for the source
//
// Parameters:
//  Form     - ClientApplicationForm - the form in which the tree is built
//  Source  - CatalogRef.Warehouses, CatalogRef.LoyaltyCardKinds, CatalogRef.TermsOfSale -
//              the source of the discount.
//
Procedure BuildDiscountMarkUpTreeInForm(Form, Source) Export
	
	SetPrivilegedMode(True);
	
	TableDiscountsMarkups = ValidityOfDiscountsMarkupsSource(Source, Form.SliceDate);
	
	ArrayOfDiscounts = New Array;
	
	If ValueIsFilled(Form.OptionForDisplayingDiscounts) Then
		
		Filter = New Structure;
		If Form.OptionForDisplayingDiscounts = "OnlyValidOnes" Then
			Filter.Insert("Status", Enums.DiscountValidityStatuses.Valid);
		ElsIf Form.OptionForDisplayingDiscounts = "CurrentAndCancelled" Then
			Filter.Insert("Use", True);
		EndIf;
		
		FoundRows = TableDiscountsMarkups.FindRows(Filter);
		For Each TSRow In FoundRows Do
			ArrayOfDiscounts.Add(TSRow.DiscountMarkup);
		EndDo;
		
	Else
		Query = New Query(
		"SELECT
		|	DiscountsMarkups.Ref
		|FROM
		|	Catalog.DiscountsMarkups AS DiscountsMarkups
		|WHERE
		|	NOT DiscountsMarkups.IsFolder");
		ArrayOfDiscounts = Query.Execute().Unload().UnloadColumn("Ref");
	EndIf;
	
	DiscountTree = CreateDiscountTree(ArrayOfDiscounts);
	
	DiscountTree.Columns.Add("PictureIndex", New TypeDescription("Number"));
	DiscountTree.Columns.Add("Status",         New TypeDescription("EnumRef.DiscountValidityStatuses"));
	DiscountTree.Columns.Add("StartDate",     New TypeDescription("Date"));
	DiscountTree.Columns.Add("EndDate",  New TypeDescription("Date"));
	
	BuildDiscountMarkUpTreeRecursively(DiscountTree, TableDiscountsMarkups);
	
	Form.ValueToFormAttribute(DiscountTree, "DiscountsMarkups");
	
EndProcedure

// The General part of the event handlers "Joinserver" of the discount action sources.
//
// Parameters:
//  Form     - ClientApplicationForm - the form for which actions are performed
//  Source  - CatalogRef.Warehouses, CatalogRef.LoyaltyCardKinds, CatalogRef.TermsOfSale -
//              the source of the discount.
//  CalculateQuantityInformation - Boolean - indicates whether information about the number of active discounts should be calculated by source.
//
Procedure WhenCreatingDiscountSourcesOnServer(Form, Source, CalculateQuantityInformation = True) Export

	Form.OptionForDisplayingDiscounts = "OnlyValidOnes";
	Form.SliceDate = CurrentSessionDate();
	
	If Not GetFunctionalOption("UseDiscountsMarkupsInSales") Then
		Return;
	EndIf;
	
	BuildDiscountMarkUpTreeInForm(Form, Source);
	If CalculateQuantityInformation Then
		Form.InformationOnDiscountNumber = InformationOnDiscountNumber(Source, CurrentSessionDate());
	EndIf;

EndProcedure

// Fills copy the register information of "Distintegrating". 
//
// Parameters:
// 	CurrentObject - CatalogObject.TermsOfSale, CatalogObject.LoyaltyCardKinds, CatalogObject.Warehouses -
// 	                Object for the new entry.
// 	CopyingValue - CatalogRef.TermsOfSale, CatalogRef.LoyaltyCardKinds, CatalogRef.Warehouses -
//                        Reference to the source-the copy object.
Procedure WhenRecordingOnServerOfSourcesOfValidityOfDiscountsMargins(CurrentObject, CopyingValue) Export
	
	If Not CopyingValue.IsEmpty() Then
		
		Query = New Query;
		Query.Text = "SELECT
		|	TheEffectOfDiscountsMarkupsASliceOfTheLast.Period AS Period,
		|	TheEffectOfDiscountsMarkupsASliceOfTheLast.DiscountMarkup AS DiscountMarkup,
		|	TheEffectOfDiscountsMarkupsASliceOfTheLast.Status AS Status,
		|	TheEffectOfDiscountsMarkupsASliceOfTheLast.PartnersSegment AS PartnersSegment
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&SliceDate, Source = &Source) AS
		|		TheEffectOfDiscountsMarkupsASliceOfTheLast
		|
		|UNION ALL
		|
		|SELECT
		|	ValidityOfDiscountsMarkups.Period,
		|	ValidityOfDiscountsMarkups.DiscountMarkup,
		|	ValidityOfDiscountsMarkups.Status,
		|	ValidityOfDiscountsMarkups.PartnersSegment
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups AS ValidityOfDiscountsMarkups
		|WHERE
		|	ValidityOfDiscountsMarkups.Period > &SliceDate
		|	AND ValidityOfDiscountsMarkups.Source = &Source";
		
		Query.SetParameter("SliceDate", CurrentSessionDate());
		Query.SetParameter("Source", CopyingValue);
		
		Selection = Query.Execute().Select();
		If Selection.Count() > 0 Then
			EmployeeResponsible = Users.CurrentUser();;
		EndIf;
		
		While Selection.Next() Do
			
			RecordManager = InformationRegisters.ValidityOfDiscountsMarkups.CreateRecordManager();
			FillPropertyValues(RecordManager, Selection);
			RecordManager.Source = CurrentObject.Ref;
			RecordManager.EmployeeResponsible = EmployeeResponsible;
			RecordManager.Write(True);
			
		EndDo;
		
		CopyingValue = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
		
	EndIf;
	
EndProcedure

// Sets the conditional design for the tree of discounts (markups) in the source form
//
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance - conditional form design to which elements are added
//  Items - FormItems - a collection of form elements that are set to conditional formatting.
//  TableName - String - name of the discount table
//
Procedure SetConditionalAppearanceOfDiscountSourceForm(ConditionalAppearance, Items, TableName = "DiscountsMarkups") Export
	
	// "Status" - not valid
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemTable = Items[TableName]; // FormTable
	ItemField.Field = New DataCompositionField(ItemTable.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TableName + ".Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	// The discount (margin) is valid indefinitely

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemTable = Items["DiscountsMarkupsValidityEndDate"]; // FormTable
	ItemField.Field = New DataCompositionField(ItemTable.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TableName + ".EndDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = '00010101';

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TableName + ".StartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = '00010101';

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
													|ru = '<бессрочно>';
													|en = '<permanent>'; fa = '<دائمی>';
													|it = '<illimitato>';
													|pl = '<permanent>';
													|tr = '<süresiz>'"));
	
EndProcedure

Procedure FillInDataTableOfSubordinateRows(CalculationResult2, SubordinateRow)
	
	For Each TableRow In SubordinateRow.CalculationResult2 Do
		If SubordinateRow.IsFolder Then
			NewRow = CalculationResult2.Add();
			FillPropertyValues(NewRow, TableRow);
			NewRow.AddlOrderingAttribute = SubordinateRow.AddlOrderingAttribute;
		Else
			If TableRow.Valid Then
				NewRow = CalculationResult2.Add();
				FillPropertyValues(NewRow, TableRow);
				NewRow.AddlOrderingAttribute = SubordinateRow.AddlOrderingAttribute;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// This function performs joins of subordinate data tables.
//
// Returns:
//	ValueTable - combined data table:
//		* ConnectionKey - Number
//		* Sum - Number
//		* Details - ValueTable
//		* AddlOrderingAttribute - Number
//
Function DataTableOnMethodOfJointApplicationForDocumentAsWhole(TreeRow)
	
	CalculationResult2 = New ValueTable;
	CalculationResult2.Columns.Add("ConnectionKey",                 New TypeDescription("Number"));
	CalculationResult2.Columns.Add("Sum",                     New TypeDescription("Number"));
	CalculationResult2.Columns.Add("Details",               New TypeDescription("ValueTable"));
	CalculationResult2.Columns.Add("AddlOrderingAttribute", New TypeDescription("Number"));
	
	Table = New ValueTable;
	Table.Columns.Add("TreeRow");
	Table.Columns.Add("Sum",         New TypeDescription("Number"));
	Table.Columns.Add("AddlOrderingAttribute", New TypeDescription("Number"));
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		If Not SubordinateRow.IsFolder Then // This is a discount, not a group
			
			If Not SubordinateRow.ConditionParameters_.ConditionsAreFulfilled Then
				Continue;
			EndIf;
			
			If SubordinateRow.Managed And Not SubordinateRow.AssignedByUser Then
				Continue;
			EndIf;
			
		EndIf;
		
		NewRow = Table.Add();
		NewRow.TreeRow              = SubordinateRow;
		NewRow.AddlOrderingAttribute = SubordinateRow.AddlOrderingAttribute;
		
		For Each TableRow In SubordinateRow.CalculationResult2 Do
			If SubordinateRow.IsFolder Then
				NewRow.Sum = NewRow.Sum + TableRow.Sum;
			Else
				If TableRow.Valid Then
					NewRow.Sum = NewRow.Sum + TableRow.Sum;
				EndIf;
			EndIf;
		EndDo;
		
	EndDo;
	
	If TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Max Then
		Table.Sort("Sum Desc, AddlOrderingAttribute");
	ElsIf TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Min Then
		Table.Sort("Sum Asc, AddlOrderingAttribute");
	ElsIf TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Exclusion Then
		Table.Sort("AddlOrderingAttribute");
	EndIf;
	
	For Each TSRow In Table Do
		FillInDataTableOfSubordinateRows(CalculationResult2, TSRow.TreeRow);
		Break;
	EndDo;
	
	Return CalculationResult2;
	
EndFunction

// The function returns a table of current discounts (markups)
//
// Returns:
//	Array of CatalogRef.DiscountsMarkups - Decoding of discounts.
//
Function DiscountMarkupsForRetailers(CurrentDate, Warehouse, LoyaltyCard)
	
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	UseLoyaltyCards  = GetFunctionalOption("UseLoyaltyCards");
	
	WarehouseGroups = New Array;
	If UseSeveralWarehouses Then
		Query = New Query(
		"SELECT DISTINCT
		|	T.Ref.Parent AS Ref
		|FROM
		|	Catalog.Warehouses AS T
		|WHERE
		|	T.Ref IN (&Warehouse)
		|TOTALS BY
		|	Ref ONLY HIERARCHY
		|");
		Query.Parameters.Insert("Warehouse", Warehouse);
		WarehouseGroups = Query.Execute().Unload().UnloadColumn("Ref");
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	Table.DiscountMarkup AS DiscountMarkup
	|FROM
	|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&CurrentDate,
	|		Source = VALUE(Catalog.Warehouses.EmptyRef)
	|		OR &UseSeveralWarehouses
	|	) AS Table
	|WHERE
	|	Table.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
	|";

	If UseSeveralWarehouses Then
		QueryText = StrReplace(QueryText, "OR &UseSeveralWarehouses", " OR Source = &Warehouse OR Source IN (&WarehouseGroups)");
	Else	
		QueryText = StrReplace(QueryText, "OR &UseSeveralWarehouses", "");
	EndIf;
	
	If UseLoyaltyCards Then
		QueryText = QueryText + "
		|UNION ALL
		|
		|SELECT
		|	Table.DiscountMarkup
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&CurrentDate, Source REFS Catalog.LoyaltyCardKinds) AS Table
		|		INNER JOIN Catalog.LoyaltyCards AS LoyaltyCards
		|		ON (LoyaltyCards.Owner = Table.Source)
		|			AND (LoyaltyCards.Ref = &LoyaltyCard)
		|WHERE
		|	LoyaltyCards.Owner.ValidityStartDate <= &CurrentDate
		|	AND CASE
		|			WHEN LoyaltyCards.Owner.ValidityEndDate = DATETIME(1, 1, 1)
		|				THEN TRUE
		|			ELSE ENDOFPERIOD(LoyaltyCards.Owner.ValidityEndDate, DAY) >= &CurrentDate
		|		END
		|	AND Table.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
		|	AND (NOT Table.DiscountMarkup.DiscountApplicationMethod = VALUE(Enum.DiscountMarkupApplicationMethods.GrantBonusPoints)
		|		OR Table.DiscountMarkup.DiscountApplicationMethod = VALUE(Enum.DiscountMarkupApplicationMethods.GrantBonusPoints)
		|			AND NOT LoyaltyCards.Partner = VALUE(Catalog.Partners.RetailCustomer))
		|";
	EndIf;
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("CurrentDate", CurrentDate);
	
	If UseLoyaltyCards Then
		Query.Parameters.Insert("LoyaltyCard", LoyaltyCard);
	EndIf;
	If UseSeveralWarehouses Then
		Query.Parameters.Insert("Warehouse",         Warehouse);
		Query.Parameters.Insert("WarehouseGroups", WarehouseGroups);
	EndIf;
	
	Return Query.Execute().Unload().UnloadColumn("DiscountMarkup");
	
EndFunction

// The function returns a table of current discounts (markups)
//
// Returns:
//	Array of CatalogRef.DiscountsMarkups - Decoding of discounts.
//
Function DiscountMarginsForWholesale(CurrentDate, Warehouse, Terms, LoyaltyCard) Export
	
	UseSeveralWarehouses     = GetFunctionalOption("UseSeveralWarehouses");
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	UseLoyaltyCards      = GetFunctionalOption("UseLoyaltyCards");
	
	WarehouseGroups = New Array;
	If UseSeveralWarehouses Then
		Query = New Query(
		"SELECT DISTINCT
		|	T.Ref.Parent AS Ref
		|FROM
		|	Catalog.Warehouses AS T
		|WHERE
		|	T.Ref IN (&Warehouse)
		|TOTALS BY
		|	Ref ONLY HIERARCHY
		|");
		Query.Parameters.Insert("Warehouse", Warehouse);
		WarehouseGroups = Query.Execute().Unload().UnloadColumn("Ref");
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	Table.DiscountMarkup AS DiscountMarkup
	|FROM
	|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&CurrentDate,
	|		Source = VALUE(Catalog.Warehouses.EmptyRef)
	|		OR &UseSeveralWarehouses
	|		OR ToUseTermsOfSales
	|	) AS Table
	|WHERE
	|	Table.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
	|";
	
	If UseSeveralWarehouses Then
		QueryText = StrReplace(QueryText, "OR &UseSeveralWarehouses", " OR Source = &Warehouse OR Source IN (&WarehouseGroups)");
	Else	
		QueryText = StrReplace(QueryText, "OR &UseSeveralWarehouses", "");
	EndIf;
	
	If ToUseTermsOfSales Then
		QueryText = StrReplace(QueryText, "OR ToUseTermsOfSales", " OR Source = &Terms");
	Else	
		QueryText = StrReplace(QueryText, "OR ToUseTermsOfSales", "");
	EndIf;
	
	If UseLoyaltyCards Then
		QueryText = QueryText + "
		|UNION ALL
		|
		|SELECT
		|	Table.DiscountMarkup
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&CurrentDate, Source REFS Catalog.LoyaltyCardKinds) AS Table
		|		INNER JOIN Catalog.LoyaltyCards AS LoyaltyCards
		|		ON (LoyaltyCards.Owner = Table.Source)
		|			AND (LoyaltyCards.Ref = &LoyaltyCard)
		|WHERE
		|	LoyaltyCards.Owner.ValidityStartDate <= &CurrentDate
		|	AND CASE
		|			WHEN LoyaltyCards.Owner.ValidityEndDate = DATETIME(1, 1, 1)
		|				THEN TRUE
		|			ELSE ENDOFPERIOD(LoyaltyCards.Owner.ValidityEndDate, DAY) >= &CurrentDate
		|		END
		|	AND Table.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
		|	AND (NOT Table.DiscountMarkup.DiscountApplicationMethod = VALUE(Enum.DiscountMarkupApplicationMethods.GrantBonusPoints)
		|		OR Table.DiscountMarkup.DiscountApplicationMethod = VALUE(Enum.DiscountMarkupApplicationMethods.GrantBonusPoints)
		|			AND NOT LoyaltyCards.Partner = VALUE(Catalog.Partners.RetailCustomer))
		|";
	EndIf;
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("CurrentDate", CurrentDate);
	
	If ToUseTermsOfSales Then
		Query.Parameters.Insert("Terms", Terms);
	EndIf;
	If UseLoyaltyCards Then
		Query.Parameters.Insert("LoyaltyCard", LoyaltyCard);
	EndIf;
	If UseSeveralWarehouses Then
		Query.Parameters.Insert("Warehouse",         Warehouse);
		Query.Parameters.Insert("WarehouseGroups", WarehouseGroups);
	EndIf;
	
	Return Query.Execute().Unload().UnloadColumn("DiscountMarkup");
	
EndFunction

// The function returns a table of current discounts (markups)
//
// Returns:
//	Array of CatalogRef.DiscountsMarkups - Decoding of discounts.
//
Function DiscountMarginsForServices(CurrentDate, Terms, LoyaltyCard)
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	UseLoyaltyCards      = GetFunctionalOption("UseLoyaltyCards");
	
	QueryText = "
	|SELECT DISTINCT
	|	Table.DiscountMarkup AS DiscountMarkup
	|FROM
	|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&CurrentDate,
	|		Source = VALUE(Catalog.Warehouses.EmptyRef)
	|		OR &ToUseTermsOfSales
	|	) AS Table
	|WHERE
	|	Table.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
	|";
	If ToUseTermsOfSales Then
		QueryText = StrReplace(QueryText, "OR &ToUseTermsOfSales", "OR Source = &Terms");
	Else	
		QueryText = StrReplace(QueryText, "OR &ToUseTermsOfSales", "");
	EndIf;
	
	If UseLoyaltyCards Then
		QueryText = QueryText + "
		|UNION ALL
		|
		|SELECT
		|	Table.DiscountMarkup
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&CurrentDate, Source REFS Catalog.LoyaltyCardKinds) AS Table
		|		INNER JOIN Catalog.LoyaltyCards AS LoyaltyCards
		|		ON (LoyaltyCards.Owner = Table.Source)
		|			AND (LoyaltyCards.Ref = &LoyaltyCard)
		|WHERE
		|	LoyaltyCards.Owner.ValidityStartDate <= &CurrentDate
		|	AND CASE
		|			WHEN LoyaltyCards.Owner.ValidityEndDate = DATETIME(1, 1, 1)
		|				THEN TRUE
		|			ELSE ENDOFPERIOD(LoyaltyCards.Owner.ValidityEndDate, DAY) >= &CurrentDate
		|		END
		|	AND Table.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
		|";
	EndIf;
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("CurrentDate", CurrentDate);
	
	If ToUseTermsOfSales Then
		Query.Parameters.Insert("Terms", Terms);
	EndIf;
	If UseLoyaltyCards Then
		Query.Parameters.Insert("LoyaltyCard", LoyaltyCard);
	EndIf;
	
	Return Query.Execute().Unload().UnloadColumn("DiscountMarkup");
	
EndFunction

// The function fills in the link keys in the "Products" tabular part of the document.
//
Procedure FillInCommunicationKeysInTablePart(Object, TSName, SalesInExcessOfOrder = False) Export
	
	If SalesInExcessOfOrder Then
	
		IndexOf = 0;
		RowsArray = New Array;
		For Each TSRow In Object[TSName] Do
			If TSRow.RowCode = 0 Then	
				RowsArray.Add(TSRow);
			Else
				IndexOf = Max(IndexOf, TSRow.ConnectionKey);
			EndIf;
		EndDo;
		
		For Each TSRow In RowsArray Do
			IndexOf = IndexOf + 1;
			TSRow.ConnectionKey = IndexOf;
		EndDo;
	Else
	
		IndexOf = 0;
		For Each TSRow In Object[TSName] Do
			IndexOf = IndexOf + 1;
			TSRow.ConnectionKey = IndexOf;
		EndDo;
	
	EndIf;
	
EndProcedure

// the function gets the Cur time of the object
//
// Parameters:
//  Object  - DocumentObject - the object to get the Cur time for.
//
// Returns:
//   Date   - The current time of the object.
//
Function GetCurObjectTime(Object) Export
	
	CurrentDate = ?(ValueIsFilled(Object.Ref), Object.Date,
		?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
	
	CurrentTime = '00010101' + (CurrentDate - BegOfDay(CurrentDate));
	
	Return CurrentTime;
	
EndFunction

// the function gets the Cur date time of the object
//
// Parameters:
//  Object  - DocumentObject - the object to get the Cur time for.
//
// Returns:
//   Date   - The current time of the object.
//
Function GetCurDateOfPlace(Object) Export
	
	CurrentDate = ?(ValueIsFilled(Object.Ref), Object.Date,
		?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
	
	Return CurrentDate;
	
EndFunction

// The procedure fills in the service structure " manageable Slides "of the" input Parameters " structure.
//
Procedure PrepareDataOnSelectedManagedDiscounts(Object, CalculationParameters, InputParameters) Export
	
	CalculationParameters.Insert("ManagedDiscounts", New Array);
	
	// If the managed discounts are not transferred, we will get them from the previous calculation
	If InputParameters.Property("ManagedDiscounts") And InputParameters.ManagedDiscounts <> Undefined And InputParameters.ManagedDiscounts.Count() > 0 Then
		For Each ManagedDiscount In InputParameters.ManagedDiscounts Do
			CalculationParameters.ManagedDiscounts.Add(ManagedDiscount.Value);
		EndDo;
	Else
		If InputParameters.RestoreManagedDiscounts Then
			FoundRows = Object.DiscountsMarkups.FindRows(New Structure("ConnectionKey", 0));
			For Each TSRow In FoundRows Do
				CalculationParameters.ManagedDiscounts.Add(TSRow.DiscountMarkup);
			EndDo;
		EndIf;
	EndIf;
	
	Messages = New ValueTable;
	Messages.Columns.Add("DiscountMarkup",  New TypeDescription("CatalogRef.DiscountsMarkups"));
	Messages.Columns.Add("RemindLater", New TypeDescription("Boolean"));
	Messages.Indexes.Add("DiscountMarkup");
	
	FoundRows = Object.DiscountsMarkups.FindRows(New Structure("ConnectionKey", -1));
	For Each TSRow In FoundRows Do
		Message = Messages.Add();
		Message.DiscountMarkup  = TSRow.DiscountMarkup;
		Message.RemindLater = TSRow.RemindLater;
	EndDo;
	
	CalculationParameters.Insert("Messages", Messages);
	
EndProcedure

// The procedure saves the selected managed discounts in the table part of "discount Markups".
//
Procedure SaveDataAboutSelectedManagedDiscounts(TableDiscountsMarkups, CalculationParameters)
	
	For Each ManagedDiscount In CalculationParameters.ManagedDiscounts Do
		NewRow = TableDiscountsMarkups.Add();
		NewRow.ConnectionKey     = 0;
		NewRow.Sum         = 0;
		NewRow.DiscountMarkup = ManagedDiscount;
	EndDo;
	
	CurMessages_ = TableDiscountsMarkups.Copy(New Structure("ThisIsMessage", True), "DiscountMarkup");
	CurMessages_.GroupBy("DiscountMarkup");
	
	For Each StringTSMessage In CurMessages_ Do
		
		TSRow = TableDiscountsMarkups.Add();
		TSRow.ConnectionKey     = -1;
		TSRow.DiscountMarkup = StringTSMessage.DiscountMarkup;
		
		SavedMessages = CalculationParameters.Messages.FindRows(New Structure("DiscountMarkup", StringTSMessage.DiscountMarkup));
		If SavedMessages.Count() > 0 Then
			For Each Message In SavedMessages Do
				TSRow.RemindLater = Message.RemindLater;
			EndDo;
		Else
			// New message
			TSRow.RemindLater = True;
		EndIf;
		
	EndDo;
	
EndProcedure

// Generates a table of discounts (mark-UPS) by source
//
// Parameters:
//  Source  - CatalogRef.Warehouses, CatalogRef.LoyaltyCardKinds, CatalogRef.TermsOfSale -
//              the source of the discount.
//  Date      - Date - the date when discounts (mark-UPS) are cut off.
//
// Returns:
//   ValueTable - a table containing discounts, Status and validity period. Structure:
//   	* DiscountMarkup - CatalogRef.DiscountsMarkups - 
//   	* Status        - EnumRef.DiscountValidityStatuses - 
//   	* Use - Boolean - Use
//   	* StartDate    - Date - Start date
//   	* EndDate - Date - Expiry date
//
Function ValidityOfDiscountsMarkupsSource(Source, Date)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	TheEffectOfDiscountsMarkupsASliceOfTheLast.DiscountMarkup                                                              AS DiscountMarkup,
	|	ISNULL(TheEffectOfDiscountsMarkupsASliceOfTheLast.Status, VALUE(Enum.DiscountValidityStatuses.NotValid)) AS Status,
	|	
	|	CASE
	|		WHEN TheEffectOfDiscountsMarkupsASliceOfTheLast.Status IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Use,
	|	
	|	ISNULL(TheEffectOfDiscountsMarkupsASliceOfTheLast.Period, DATETIME(1, 1, 1)) AS StartDate,
	|	
	|	CASE WHEN TheEffectOfDiscountsMarkupsASliceOfTheLast.Period IS NULL THEN
	|		ISNULL(DATEADD(TheEffectOfDiscountsMarkupsASliceOfTheFirst.Period, DAY, -1), DATETIME(1, 1, 1)) 
	|	ELSE
	|		ISNULL(DATEADD(Table.Period, DAY, -1), DATETIME(1, 1, 1))
	|	END AS EndDate
	|	
	|FROM
	|	Catalog.DiscountsMarkups AS TableDiscountsMarkups
	|		
	|		LEFT JOIN
	|			InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&SliceDate, Source = &Source) AS TheEffectOfDiscountsMarkupsASliceOfTheLast
	|			ON TheEffectOfDiscountsMarkupsASliceOfTheLast.DiscountMarkup = TableDiscountsMarkups.Ref
	|		
	|		LEFT JOIN (SELECT
	|			MIN(T.Period) AS Period,
	|			T.DiscountMarkup AS DiscountMarkup
	|		FROM
	|			InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&SliceDate, Source = &Source) AS CrossSection
	|				LEFT JOIN InformationRegister.ValidityOfDiscountsMarkups AS T
	|				ON (T.DiscountMarkup = CrossSection.DiscountMarkup)
	|					AND T.Source = CrossSection.Source
	|					AND T.Period > CrossSection.Period
	|					AND T.Status <> CrossSection.Status
	|		GROUP BY
	|			T.DiscountMarkup) AS Table
	|		ON (Table.DiscountMarkup = TableDiscountsMarkups.Ref)
	|		
	|		LEFT JOIN InformationRegister.ValidityOfDiscountsMarkups.SliceFirst(
	|				&SliceDate,
	|				Source = &Source) AS TheEffectOfDiscountsMarkupsASliceOfTheFirst
	|		ON TheEffectOfDiscountsMarkupsASliceOfTheFirst.DiscountMarkup = TableDiscountsMarkups.Ref
	|WHERE
	|	    NOT TheEffectOfDiscountsMarkupsASliceOfTheLast.Period IS NULL
	|	OR NOT TheEffectOfDiscountsMarkupsASliceOfTheFirst.Period IS NULL
	|");
	
	Query.SetParameter("SliceDate", Date);
	Query.SetParameter("Source", Source);
	
	Return Query.Execute().Unload();
	
EndFunction

// Parameters:
// 	Object 	- FormDataStructure - must contain:
// 				* Ref - DocumentRef.CommercialProposalForCustomer
// 				* Taxation - See CommercialProposalsDocumentsClientServerTM.TaxationOfVATOnTaxationOfCommercialOffers.Taxation
//			- DocumentObject.CommercialProposalForCustomer - 
//
//	VATTaxation - See CommercialProposalsDocumentsClientServerTM.TaxationOfVATOnTaxationOfCommercialOffers.Taxation
//	StandardProcessing - Boolean - returned value
Procedure WhenDeterminingVATTaxation(Object, VATTaxation, StandardProcessing) Export
	
	If TypeOf(Object) = Type("FormDataStructure")
		And Object.Property("Ref") Then
			
		If TypeOf(Object.Ref) = Type("DocumentRef.CommercialProposalForCustomer")
			And CommonClientServer.HasAttributeOrObjectProperty(Object, "Taxation") Then

			StandardProcessing = False;
			
			VATTaxation = 
				CommercialProposalsDocumentsClientServerTM.TaxationOfVATOnTaxationOfCommercialOffers(Object.Taxation);
				
		EndIf;

	EndIf;
	
EndProcedure

Function RequestTextForUpdatingCachedRequestsDiscountsMargins()
	QueryText =
	"SELECT
	|	DiscountsMarkups.Ref AS Ref
	|FROM
	|	Catalog.DiscountsMarkups AS DiscountsMarkups
	|WHERE
	|	NOT DiscountsMarkups.IsFolder
	|	AND NOT DiscountsMarkups.MethodsOfProviding IN
	|		(SELECT
	|			AdditionalReportsAndDataProcessors.Ref AS Ref
	|		FROM
	|			Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors)";
	
	Return QueryText;
EndFunction

Function RequestTextForUpdatingCachedRequestsTermsOfDiscountsAndMargins()
	QueryText =
	"SELECT
	|	DiscountMarkupTerms.Ref AS Ref
	|FROM
	|	Catalog.DiscountMarkupTerms AS DiscountMarkupTerms
	|WHERE
	|	(DiscountMarkupTerms.DiscountMarkupCondition = VALUE(Enum.DiscountMarkupTerms.ForOneTimeSalesVolume)
	|	OR
	|		DiscountMarkupTerms.DiscountMarkupCondition = VALUE(Enum.DiscountMarkupTerms.ForAccumulatedSalesVolume))";
	
	Return QueryText;
EndFunction

#Region ProceduresForCalculatingDiscountsMarginsOnDocuments

// Calculates discounts for the customer's order.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  InputParameters - Structure - structure with properties:
//   * OnlyPreliminaryCalculation - Boolean - Only a preliminary calculation.
//   * ApplyToObject - Boolean - Apply to an object.
//   * RestoreManagedDiscounts - Boolean - Managed to restore discounts (markups).
//   * ManagedDiscounts - Array - Managed discounts (mark-UPS).
//
// Returns:
//  Structure - structure with properties:
//   * DiscountTree - See CreateDiscountTree
//   * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//   * CalculationParameters - Structure - Structure of calculation parameters.
//
Function CalculateByCustomerOrder(Object, InputParameters)
	
	SetPrivilegedMode(True);
	
	FillInCommunicationKeysInTablePart(Object, "Goods");
	
	UseSets = GetFunctionalOption("UseSets");
	
	// Processing of the "Goods" tabular part.
	QueryText =
	"SELECT
	|	Goods.ConnectionKey          AS ConnectionKey,
	|	&SetFields,
	|	Goods.Products       AS Products,
	|	Goods.Characteristic     AS Characteristic,
	|	Goods.Package           AS Package,
	|	Goods.Series              AS Series,
	|	Goods.Warehouse              AS Warehouse,
	|	Goods.PriceKind            AS PriceKind,
	|	Goods.Count         AS Count,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Price                             AS Price,
	|	Goods.Price * Goods.NumberOfPackages AS Sum
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ConnectionKey,
	|	&TableFields,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	Table.Series,
	|	Table.Warehouse,
	|	Table.PriceKind,
	|	CatalogProducts.PriceGroup AS PriceGroup,
	|	Table.Count,
	|	Table.NumberOfPackages,
	|	Table.Price,
	|	Table.Sum
	|,&TempTableName
	|FROM
	|	TTProducts_1 AS Table
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = Table.Products
	|		,&Join
	|WHERE
	|	CASE 
	|		WHEN &ReturnPackage THEN
	|			Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	ELSE
	|		TRUE
	|	END
	|; SELECT &RequestSets
	|";
	
	GoodsTable = Object.Goods.Unload();
	
	QueryOptions = New Structure;
	QueryOptions.Insert("Goods", GoodsTable);
	QueryOptions.Insert("ReturnPackage", Object.ToReturnReusablePackage);
	DataOnProductsAndSets = DataOnProductsAndSets(QueryText, QueryOptions, UseSets);
	
	DiscountsMarkups = DiscountMarginsForWholesale(
		Object.Date,
		Object.Warehouse,
		Object.Terms,
		Object.LoyaltyCard);
	
	CalculationParameters = CalculationParameters();
	CalculationParameters.DiscountsMarkups = DiscountsMarkups;
	CalculationParameters.Partner       = Object.Partner;
	CalculationParameters.Terms    = Object.Terms;
	CalculationParameters.Recorder   = Object.Ref;
	
	// For the discount "For the form of payment".
	CalculationParameters.PaymentMethod = Object.PaymentMethod;
	
	// For a discount "For the time of sale".
	CalculationParameters.WeekDay   = Enums.WeekDays.Get(WeekDay(Object.Date) - 1);
	CalculationParameters.CurrentTime = GetCurObjectTime(Object);
	CalculationParameters.CurrentDate  = GetCurDateOfPlace(Object);
	
	// For the discount "For compliance with the payment schedule".
	CalculationParameters.PaymentSchedule = Object.PaymentSchedule;
	
	// Loyalty card
	CalculationParameters.LoyaltyCard = Object.LoyaltyCard;
	
	CalculationParameters.Goods                     = DataOnProductsAndSets.Goods;
	CalculationParameters.DocumentCurrency            = Object.Currency;
	CalculationParameters.ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	CalculationParameters.BaseCurrency              = SettingsValueCached.DefaultBaseCurrency();
	CalculationParameters.User               = Object.Manager;
	CalculationParameters.Object                     = Object;
	
	PrepareDataOnSelectedManagedDiscounts(Object, CalculationParameters, InputParameters);
	AppliedDiscountsMarkups = CalculateDiscountMarkUpTree(CalculationParameters, InputParameters);
	
	If UseSets And Not InputParameters.OnlyPreliminaryCalculation Then
		DistributeKitDiscountsByComponents(AppliedDiscountsMarkups, DataOnProductsAndSets.MatchingKeys, GoodsTable);
	EndIf;
	
	If InputParameters.ApplyToObject Then
		
		ApplyCalculationResultToCustomerOrder(Object, AppliedDiscountsMarkups);
		
	EndIf;
	
	Return AppliedDiscountsMarkups;
	
EndFunction

// Calculates discounts based on a request to return goods from a customer.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  InputParameters - Structure - structure with properties:
//   * OnlyPreliminaryCalculation - Boolean - Only a preliminary calculation.
//   * ApplyToObject - Boolean - Apply to an object.
//   * RestoreManagedDiscounts - Boolean - Managed to restore discounts (markups).
//   * ManagedDiscounts - Array - Managed discounts (mark-UPS).
//
// Returns:
//  Structure - structure with properties:
//   * DiscountTree - See CreateDiscountTree
//   * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//   * CalculationParameters - Structure - Structure of calculation parameters.
//
Function CalculateOnRequestForReturnOfGoodsFromClient(Object, InputParameters)
	
	SetPrivilegedMode(True);
	
	FillInCommunicationKeysInTablePart(Object, "SubstituteGoods");
	
	UseSets = GetFunctionalOption("UseSets");
	
	// Processing of the "Goods" tabular part.
	QueryText =
	"SELECT
	|	Goods.ConnectionKey          AS ConnectionKey,
	|	&SetFields,
	|	Goods.Products       AS Products,
	|	Goods.Characteristic     AS Characteristic,
	|	Goods.Package           AS Package,
	|	Goods.Series              AS Series,
	|	&Warehouse                    AS Warehouse,
	|	Goods.PriceKind            AS PriceKind,
	|	Goods.Count         AS Count,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Price                             AS Price,
	|	Goods.Price * Goods.NumberOfPackages AS Sum
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ConnectionKey,
	|	&TableFields,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	Table.Series,
	|	Table.Warehouse,
	|	Table.PriceKind,
	|	CatalogProducts.PriceGroup AS PriceGroup,
	|	Table.Count,
	|	Table.NumberOfPackages,
	|	Table.Price,
	|	Table.Sum
	|,&TempTableName
	|FROM
	|	TTProducts_1 AS Table
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = Table.Products
	|		,&Join
	|WHERE
	|	CASE 
	|		WHEN &ReturnPackage THEN
	|			Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	ELSE
	|		TRUE
	|	END
	|; SELECT &RequestSets
	|";
	
	GoodsTable = Object.SubstituteGoods.Unload();
	
	QueryOptions = New Structure;
	QueryOptions.Insert("Goods", GoodsTable);
	QueryOptions.Insert("ReturnPackage", Object.ToReturnReusablePackage);
	QueryOptions.Insert("Warehouse", Object.Warehouse);
	DataOnProductsAndSets = DataOnProductsAndSets(QueryText, QueryOptions, UseSets);
	
	DiscountsMarkups = DiscountMarginsForWholesale(
		Object.Date,
		Object.Warehouse,
		Object.Terms,
		Object.LoyaltyCard);
	
	CalculationParameters = CalculationParameters();
	CalculationParameters.DiscountsMarkups = DiscountsMarkups;
	CalculationParameters.Partner       = Object.Partner;
	CalculationParameters.Terms    = Object.Terms;
	CalculationParameters.Recorder   = Object.Ref;
	
	// For the discount "For the form of payment".
	CalculationParameters.PaymentMethod = Object.PaymentMethod;
	
	// For a discount "For the time of sale".
	CalculationParameters.WeekDay   = Enums.WeekDays.Get(WeekDay(Object.Date) - 1);
	CalculationParameters.CurrentTime = GetCurObjectTime(Object);
	CalculationParameters.CurrentDate  = GetCurDateOfPlace(Object);
	
	// For the discount "For compliance with the payment schedule".
	CalculationParameters.PaymentSchedule = Object.PaymentSchedule;
	
	// Loyalty card
	CalculationParameters.LoyaltyCard = Object.LoyaltyCard;
	
	CalculationParameters.Goods                     = DataOnProductsAndSets.Goods;
	CalculationParameters.DocumentCurrency            = Object.Currency;
	CalculationParameters.ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	CalculationParameters.BaseCurrency              = SettingsValueCached.DefaultBaseCurrency();
	CalculationParameters.User               = Object.Manager;
	CalculationParameters.Object                     = Object;
	
	PrepareDataOnSelectedManagedDiscounts(Object, CalculationParameters, InputParameters);
	AppliedDiscountsMarkups = CalculateDiscountMarkUpTree(CalculationParameters, InputParameters);
	
	If UseSets And Not InputParameters.OnlyPreliminaryCalculation Then
		DistributeKitDiscountsByComponents(AppliedDiscountsMarkups, DataOnProductsAndSets.MatchingKeys, GoodsTable);
	EndIf;
	
	If InputParameters.ApplyToObject Then
		
		ApplyCalculationResultToReturnOfGoodsFromCustomer(Object, AppliedDiscountsMarkups);
		
	EndIf;
	
	Return AppliedDiscountsMarkups;
	
EndFunction

// Performs the calculation of discounts on the commercial offer to the client.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  InputParameters - Structure - structure with properties:
//   * OnlyPreliminaryCalculation - Boolean - Only a preliminary calculation.
//   * ApplyToObject - Boolean - Apply to an object.
//   * RestoreManagedDiscounts - Boolean - Managed to restore discounts (markups).
//   * ManagedDiscounts - Array - Managed discounts (mark-UPS).
//   * ColumnNamePackaging - String - Name of the packing data column (optional).
//
// Returns:
//  Structure - structure with properties:
//   * DiscountTree - ValueTree - Tree of discounts (markups).
//   * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//   * CalculationParameters - Structure - Structure of calculation parameters.
//
Function CalculateAccordingToCommercialOfferToClient(Object, InputParameters)
	
	SetPrivilegedMode(True);
	
	DiscountsMarkupsServer.FillInCommunicationKeysInTablePart(Object, "Goods");
	
	UseSets = False;
	
	ColumnNamePackaging           = "UnitOfMeasure";
	ColumnNameNumberOfPackages = "Count";
	
	If InputParameters.Property("ColumnNamePackaging") 
		And Not IsBlankString(InputParameters.ColumnNamePackaging) Then
		ColumnNamePackaging = "Goods." + InputParameters.ColumnNamePackaging;
	EndIf;
	
	If InputParameters.Property("ColumnNameNumberOfPackages") Then
		 ColumnNameNumberOfPackages = "Goods." + ColumnNameNumberOfPackages;
	EndIf;
	
	// Processing of the "Goods" tabular part.
	QueryText =
	"SELECT
	|	Goods.ConnectionKey                                    AS ConnectionKey,
	|	Goods.Products                                 AS Products,
	|	Goods.Characteristic                               AS Characteristic,
	|	&GoodsPackage                                     AS Package,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Warehouses.EmptyRef)            AS Warehouse,
	|	Goods.PriceKind                                      AS PriceKind,
	|	Goods.Count                                   AS Count,
	|	&GoodsNumberOfPackages                           AS NumberOfPackages,
	|	Goods.Price                                         AS Price,
	|	Goods.Price * &GoodsNumberOfPackages             AS Sum
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ConnectionKey,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	Table.Series,
	|	Table.Warehouse,
	|	Table.PriceKind,
	|	CatalogProducts.PriceGroup AS PriceGroup,
	|	Table.Count,
	|	Table.NumberOfPackages,
	|	Table.Price,
	|	Table.Sum
	|FROM
	|	TTProducts_1 AS Table
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = Table.Products
	|		//&Join
	|";
	
	QueryText = StrReplace(QueryText, "&GoodsPackage",           ColumnNamePackaging);
	QueryText = StrReplace(QueryText, "&GoodsNumberOfPackages", ColumnNameNumberOfPackages);
	
	GoodsTable = Object.Goods.Unload();

	QueryOptions = New Structure;
	QueryOptions.Insert("Goods", GoodsTable);
	DataOnProductsAndSets = DiscountsMarkupsServer.DataOnProductsAndSets(QueryText, QueryOptions, UseSets);
	
	DiscountParametersForWholesaleTrade = New Structure;
	DiscountParametersForWholesaleTrade.Insert("NotToUseTermsOfSales", True);
	
	DiscountsMarkups = DiscountsMarkupsServer.DiscountMarginsForWholesale(
		Object.Date,
		Catalogs.Warehouses.EmptyRef(),
		Catalogs.TermsOfSale.EmptyRef(),
		Object.LoyaltyCard);
	
	CalculationParameters = DiscountsMarkupsServer.CalculationParameters();
	CalculationParameters.DiscountsMarkups = DiscountsMarkups;
	CalculationParameters.Partner       = Object.Client;
	CalculationParameters.Recorder   = Object.Ref;
	
	// For a discount "For the time of sale".
	CalculationParameters.WeekDay   = Enums.WeekDays.Get(WeekDay(Object.Date) - 1);
	CalculationParameters.CurrentTime = DiscountsMarkupsServer.GetCurObjectTime(Object);
	CalculationParameters.CurrentDate  = DiscountsMarkupsServer.GetCurDateOfPlace(Object);
	
	// Loyalty card
	CalculationParameters.LoyaltyCard = Object.LoyaltyCard;
	
	CalculationParameters.Goods                     = DataOnProductsAndSets.Goods;
	CalculationParameters.DocumentCurrency            = Object.Currency;
	CalculationParameters.ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	CalculationParameters.BaseCurrency              = SettingsValueCached.DefaultBaseCurrency();
	CalculationParameters.User               = Object.Manager;
	CalculationParameters.Object                     = Object;
	
	DiscountsMarkupsServer.PrepareDataOnSelectedManagedDiscounts(Object, CalculationParameters, InputParameters);
	AppliedDiscountsMarkups = DiscountsMarkupsServer.CalculateDiscountMarkUpTree(CalculationParameters, InputParameters);
	
	If InputParameters.ApplyToObject Then
		
		ApplyCalculationResultToCommercialOfferToClient(Object, AppliedDiscountsMarkups);
		
	EndIf;
	
	Return AppliedDiscountsMarkups;
	
EndFunction

// Calculates discounts on sales of goods and services.
//
// Parameters:
//  Object - DocumentObject.CustomerInvoice, FormDataStructure - The object where you want to calculate
//  																		 discounts (markups).
//  InputParameters - Structure - structure with properties:
//   * OnlyPreliminaryCalculation - Boolean - Only a preliminary calculation.
//   * ApplyToObject - Boolean - Apply to an object.
//   * RestoreManagedDiscounts - Boolean - Managed to restore discounts (markups).
//   * ManagedDiscounts - Array - Managed discounts (mark-UPS).
//
// Returns:
//  Structure - structure with properties:
//   * DiscountTree - See CreateDiscountTree
//   * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//   * CalculationParameters - Structure - Structure of calculation parameters.
//
Function CalculateForSaleOfGoodsServices(Object, InputParameters)
	
	If InputParameters.Property("FillInImplementationByOrder") 
		And InputParameters.FillInImplementationByOrder Then
		
		Return CalculateForSaleOfGoodsServicesByOrder(Object);
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	FillInCommunicationKeysInTablePart(Object, "Goods", InputParameters.SalesInExcessOfOrder);
	
	UseSets = GetFunctionalOption("UseSets");
	
	// Processing of the "Goods" tabular part.
	QueryText =
	"SELECT
	|	Goods.RowCode          AS RowCode,
	|	Goods.ConnectionKey          AS ConnectionKey,
	|	&SetFields,
	|	Goods.Products       AS Products,
	|	Goods.Characteristic     AS Characteristic,
	|	Goods.Package           AS Package,
	|	Goods.Series              AS Series,
	|	Goods.Warehouse              AS Warehouse,
	|	Goods.PriceKind            AS PriceKind,
	|	Goods.Count         AS Count,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Price                             AS Price,
	|	Goods.NumberOfPackages * Goods.Price AS Sum
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ConnectionKey,
	|	&TableFields,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	Table.Series,
	|	Table.Warehouse,
	|	Table.PriceKind,
	|	CatalogProducts.PriceGroup AS PriceGroup,
	|	Table.Count,
	|	Table.NumberOfPackages,
	|	Table.Price,
	|	Table.Sum
	|,&TempTableName
	|FROM
	|	TTProducts_1 AS Table
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = Table.Products
	|		,&Join
	|WHERE
	|	CASE 
	|		WHEN &ReturnPackage THEN
	|			Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	ELSE
	|		TRUE
	|	END
	|	AND CASE 
	|		WHEN &SalesInExcessOfOrder THEN 
	|			Table.RowCode = 0 
	|		ELSE 
	|			TRUE
	|	END
	|; SELECT &RequestSets
	|";
	
	GoodsTable = Object.Goods.Unload();
	
	QueryOptions = CalculationParameters();
	QueryOptions.Insert("Goods", GoodsTable);
	QueryOptions.Insert("SalesInExcessOfOrder", InputParameters.SalesInExcessOfOrder);
	QueryOptions.Insert("ReturnPackage", Object.ToReturnReusablePackage);
	
	DataOnProductsAndSets = DataOnProductsAndSets(QueryText, QueryOptions, UseSets);
	
	DiscountsMarkups = DiscountMarginsForWholesale(
		Object.Date,
		Object.Warehouse,
		Object.Terms,
		Object.LoyaltyCard);
	
	CalculationParameters = CalculationParameters();
	CalculationParameters.DiscountsMarkups = DiscountsMarkups;
	CalculationParameters.Partner       = Object.Partner;
	CalculationParameters.Terms    = Object.Terms;
	CalculationParameters.Recorder   = Object.Ref;
	
	// For the discount "For the form of payment".
	CalculationParameters.PaymentMethod = Object.PaymentMethod;
	
	// For a discount "For the time of sale".
	CalculationParameters.WeekDay   = Enums.WeekDays.Get(WeekDay(Object.Date) - 1);
	CalculationParameters.CurrentTime = GetCurObjectTime(Object);
	CalculationParameters.CurrentDate  = GetCurDateOfPlace(Object);
	
	// For the discount "For compliance with the payment schedule".
	CalculationParameters.PaymentSchedule = Undefined;
	
	// Loyalty card
	CalculationParameters.LoyaltyCard = Object.LoyaltyCard;
	
	CalculationParameters.Goods                     = DataOnProductsAndSets.Goods;
	CalculationParameters.DocumentCurrency            = Object.Currency;
	CalculationParameters.ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	CalculationParameters.BaseCurrency              = SettingsValueCached.DefaultBaseCurrency();
	CalculationParameters.User               = Object.Manager;
	CalculationParameters.Object                     = Object;
	
	PrepareDataOnSelectedManagedDiscounts(Object, CalculationParameters, InputParameters);
	AppliedDiscountsMarkups = CalculateDiscountMarkUpTree(CalculationParameters, InputParameters);
	
	If UseSets And Not InputParameters.OnlyPreliminaryCalculation Then
		DistributeKitDiscountsByComponents(AppliedDiscountsMarkups, DataOnProductsAndSets.MatchingKeys, GoodsTable);
	EndIf;
	
	If InputParameters.ApplyToObject Then
		
		ApplyCalculationResultToSaleOfGoodsServices(Object, AppliedDiscountsMarkups, InputParameters.SalesInExcessOfOrder);
		
	EndIf;
	
	Return AppliedDiscountsMarkups;
	
EndFunction

// Calculates discounts on sales of goods and services.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//
// Returns:
//  Structure - Structure without properties
//
Function CalculateForSaleOfGoodsServicesByOrder(Object)
	
	Object.DiscountsMarkups.Clear();
	Object.BonusPointAccrual.Clear();
	
	FillInCommunicationKeysInTablePart(Object, "Goods");
	
	UseLoyaltyPrograms = GetFunctionalOption("UseLoyaltyPrograms");

	DataFromOrder = DiscountsMarkupsFillingServer.DiscountsMarginsOnOrder(Object);
	DiscountsOrderMargins = DataFromOrder.DiscountsOrderMargins;
	TableOfGoods = DataFromOrder.TableOfGoods;
	
	DateDifferenceBetweenOrderAndImplementationInSeconds = 0;
	
	If UseLoyaltyPrograms Then
	
		AccrualOfBonusPointsOfOrder = DataFromOrder.AccrualOfBonusPointsOfOrder;
		
		If ValueIsFilled(Object.SalesOrder)
			And (TypeOf(Object.Ref) = Type("DocumentRef.CustomerInvoiceServices")
				Or TypeOf(Object.Ref) = Type("DocumentRef.CustomerInvoice")) Then
			SalesOrderDate = BegOfDay(Common.ObjectAttributeValue(Object.SalesOrder, "Date"));
			DocumentSalesOfGoodsAndServicesDate = BegOfDay(Object.Date);
			DateDifferenceBetweenOrderAndImplementationInSeconds = DocumentSalesOfGoodsAndServicesDate - SalesOrderDate;
		EndIf;
		
		LoyaltyProgram = New Structure("LoyaltyProgram, 
			|BonusConversionCurrency, 
			|ConversionRateOfBonusesIntoCurrency,
			|StructureOfCurrencyConversionRates,
			|StructureOfDocumentExchangeRates");
		
		LoyaltyPrograms = AccrualOfBonusPointsOfOrder.Copy();
		
		LoyaltyPrograms.GroupBy("LoyaltyProgram, 
			|BonusConversionCurrency, 
			|ConversionRateOfBonusesIntoCurrency");
		
		If LoyaltyPrograms.Count() > 1 Then
			
			UseLoyaltyPrograms = False;
			
			ErrorText = NStr("vi = 'Đã tìm thấy các chương trình khách hàng thân thiết khác để tính điểm thưởng. Không thể giao các đơn hàng 
				| có chương trình tích điểm khác nhau vào một chứng từ.';
				|ru = 'Обнаружены разные программы лояльности для начисления бонусных баллов. Заказы 
				|с разными бонусными программами лояльности не могут быть отгружены в одном документе.';
				|en = 'Different loyalty programs are found for accrual of bonus points. Orders 
				| with different loyalty programs cannot be shipped in one document.'; fa = 'Different loyalty programs are found for accrual of bonus points. Orders 
				| with different loyalty programs cannot be shipped in one document.';
				|it = 'Sono stati rilevati programmi fedeltà per il calcolo di punti bonus. Gli ordini 
				|con diversi programmi bonus fedeltà non possono essere caricati in un documento.';
				|pl = 'Wykryto różne programy lojalnościowe do naliczenia punktów bonusowych. Zamówienia  
				|z różnymi lojalnościowymi programami bonusowymi nie mogą być wystawione w jednym dokumencie.';
				|tr = 'Bonus puan vermek için farklı sadakat programları tespit edilmiştir. Farklı sadakat programlarına sahip siparişler
				| aynı belge içinde gönderilemez.'");
			Raise ErrorText;
		ElsIf LoyaltyPrograms.Count() = 1 Then
			FillPropertyValues(LoyaltyProgram, LoyaltyPrograms[0]);
			
			If Object.Currency <> LoyaltyProgram.BonusConversionCurrency Then
				
				LoyaltyProgram.StructureOfCurrencyConversionRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(LoyaltyProgram.BonusConversionCurrency, 
					CurrentSessionDate(),
					SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
				
				LoyaltyProgram.StructureOfDocumentExchangeRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(Object.Currency, 
					CurrentSessionDate(),
					SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
				
			EndIf;
		EndIf;
		
	EndIf;
	
	NumberOfRowToProcess = 0;
	PreviousLineCode       = 0;
	PreviousOrder           = Undefined;
	RowsToProcess      = New Array;
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountOverOrder", New Structure("ImplementationReceiptByOrder, PackageDepositIsRequired",
		Object.OrderSales, Object.PackageDepositIsRequired));
	
	For Each SampleProducts_ In TableOfGoods Do
		
		FoundRows = Object.Goods.FindRows(New Structure("SalesOrder, RowCode", SampleProducts_.SalesOrder, SampleProducts_.RowCode));
		If FoundRows.Count() = 0 Then
			Continue;
		EndIf;
		
		If PreviousLineCode = SampleProducts_.RowCode And PreviousOrder = SampleProducts_.SalesOrder Then
			NumberOfRowToProcess = NumberOfRowToProcess + 1;
		Else
			NumberOfRowToProcess = 0;
		EndIf;
		
		TableRow = FoundRows[NumberOfRowToProcess];
		
		PreviousLineCode = SampleProducts_.RowCode;
		PreviousOrder     = SampleProducts_.SalesOrder;
		
		FieldList = "PercentRateOfAutomaticDiscountMarkup, PercentRateOfManualDiscount";
		
		FillPropertyValues(TableRow, SampleProducts_, FieldList);
		
		If SampleProducts_.DiscountMarkupAmount = Null Or SampleProducts_.ManualDiscount = Null Then
			ErrorText = NStr("vi = 'Có một vấn đề khi chuyển giảm giá từ đơn đặt hàng. Có lẽ không đặt tỷ giá cho loại tiền ""%Currency%""';
							|ru = 'Возникла проблемная ситуация при переносе скидок из заказа. Возможно не задан курс для валюты ""%Currency%""';
							|en = 'An issue occurred while moving discounts from the order. Exchange rate for the ""%Currency%"" currency may not be specified.'; fa = 'An issue occurred while moving discounts from the order. Exchange rate for the ""%Currency%"" currency may not be specified.';
							|it = 'Si è verificato un problema durante il trasferimento degli sconti dall''ordine. Probabilmente non è stato impostato il tasso di cambio per la valuta ""%Currency%""';
							|pl = 'Podczas przesyłania rabatów z zamówienia wystąpił problem. Być może nie ustawiono stawki dla waluty ""%Currency%""';
							|tr = 'Bir siparişten indirim aktarırken bir sorun oluştu. ""%Currency%"" para birimi için döviz kuru ayarlanmamış olabilir'");
			ErrorText = StrReplace(ErrorText, "%Currency%", Object.ARAPCurrency);
			Raise ErrorText;
		EndIf;
		
		CurAmountOfAutomaticDiscount = Round(
				SampleProducts_.OrderAmountOfAutomaticDiscount 
				* (SampleProducts_.ImplementationQuantity / SampleProducts_.OrderQuantity) 
				* SampleProducts_.CurrencyConversionRate, 
			2);
		CurAmountOfManualDiscount = Round(
				SampleProducts_.OrderAmountOfManualDiscount 
				* (SampleProducts_.ImplementationQuantity / SampleProducts_.OrderQuantity) 
				* SampleProducts_.CurrencyConversionRate, 
			2);
		CurAmountOfAccruedBonusPointsInCurrency = Round(
				SampleProducts_.OrderIsAmountOfBonusPointsAccruedInCurrency 
				* (SampleProducts_.ImplementationQuantity / SampleProducts_.OrderQuantity) 
				* SampleProducts_.CurrencyConversionRate, 
			2);
		CurAmountOfBonusPointsToBeDebitedInCurrency = Round(
				SampleProducts_.OrderIsAmountOfBonusPointsToBeDebitedInCurrency 
				* (SampleProducts_.ImplementationQuantity / SampleProducts_.OrderQuantity) 
				* SampleProducts_.CurrencyConversionRate, 
			2);
		CurAmountOfBonusPointsToBeDebited = Round(
				SampleProducts_.OrderAmountOfBonusPointsToBeDebited 
				* (SampleProducts_.ImplementationQuantity / SampleProducts_.OrderQuantity), 
			2);
		
		TableRow.DiscountMarkupAmount 				= CurAmountOfAutomaticDiscount;
		TableRow.ManualDiscount 						= CurAmountOfManualDiscount;
		TableRow.AmountOfEarnedBonusPointsInCurrency 	= CurAmountOfAccruedBonusPointsInCurrency;
		TableRow.AmountOfBonusPointsToDeductionInCurrency 		= CurAmountOfBonusPointsToBeDebitedInCurrency;
		TableRow.AmountOfBonusPointsToDeduction 				= CurAmountOfBonusPointsToBeDebited;
		
		RowsToProcess.Add(TableRow);
		
		AmountForAllocation = TableRow.DiscountMarkupAmount + TableRow.AmountOfEarnedBonusPointsInCurrency;
		
		If TableRow.ConnectionKey <> 0 Then
		
			FoundRows = DiscountsOrderMargins.FindRows(New Structure("SalesOrder, ConnectionKey", TableRow.SalesOrder, SampleProducts_.ConnectionKey));
			If FoundRows.Count() <> 0 Then
				For Each OrderDiscountsRow In FoundRows Do
					
					DiscountsRow 			= Object.DiscountsMarkups.Add();
					FillPropertyValues(DiscountsRow, OrderDiscountsRow);
					DiscountsRow.ConnectionKey	= TableRow.ConnectionKey;
 					DiscountsRow.Sum 		= (SampleProducts_.ImplementationQuantity / SampleProducts_.OrderQuantity) * DiscountsRow.Sum;
					
					AmountForAllocation 	= AmountForAllocation - DiscountsRow.Sum;
					
				EndDo;
				If AmountForAllocation <> 0 Then
					DiscountsRow.Sum = DiscountsRow.Sum + AmountForAllocation;
				EndIf;
			EndIf;
			
		EndIf;
			
		If UseLoyaltyPrograms Then
			AmountForAllocation = TableRow.AmountOfEarnedBonusPointsInCurrency;

			If ValueIsFilled(LoyaltyProgram.BonusConversionCurrency)
				And Object.Currency <> LoyaltyProgram.BonusConversionCurrency Then
				
				AmountForAllocation = ProcessingOfExchangeRatesTM.ConvertAtRate(
					AmountForAllocation,
					LoyaltyProgram.StructureOfDocumentExchangeRates,
					LoyaltyProgram.StructureOfCurrencyConversionRates);
					
			EndIf;
			
			If AmountForAllocation <> 0
				And ValueIsFilled(LoyaltyProgram.ConversionRateOfBonusesIntoCurrency) Then
				
				AmountForAllocation = AmountForAllocation / LoyaltyProgram.ConversionRateOfBonusesIntoCurrency;
			EndIf;
			
			If TableRow.ConnectionKey <> 0 Then
			
				FoundRows = AccrualOfBonusPointsOfOrder.FindRows(New Structure("SalesOrder, ConnectionKey", TableRow.SalesOrder, SampleProducts_.ConnectionKey));
				If FoundRows.Count() <> 0 Then
					
					For Each OrderBonusPointsLine In FoundRows Do
						
						BonusPointsLine = Object.BonusPointAccrual.Add();
						FillPropertyValues(BonusPointsLine, OrderBonusPointsLine);
						BonusPointsLine.AmountOfBonusPoints = (SampleProducts_.ImplementationQuantity / SampleProducts_.OrderQuantity) * BonusPointsLine.AmountOfBonusPoints;
						
						AmountForAllocation = AmountForAllocation - BonusPointsLine.AmountOfBonusPoints;
						
						If DateDifferenceBetweenOrderAndImplementationInSeconds > 0 Then
							BonusPointsLine.AccrualDate = BonusPointsLine.AccrualDate
								+ DateDifferenceBetweenOrderAndImplementationInSeconds;
							If ValueIsFilled(BonusPointsLine.DateOfDeduction) Then
								BonusPointsLine.DateOfDeduction = BonusPointsLine.DateOfDeduction
									+ DateDifferenceBetweenOrderAndImplementationInSeconds;
							EndIf;
						EndIf;
						
					EndDo;
					
					If AmountForAllocation <> 0 Then
						DiscountsRow.Sum = DiscountsRow.Sum + AmountForAllocation;
					EndIf;
					
				EndIf;
			EndIf;
		EndIf;
			
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	Object.DiscountsAreCalculated = True;
	
	Return New Structure;
	
EndFunction

// It is determined by the use of a discount (margin) for the accrual of bonus points.
// 
// Parameters:
//  DiscountMarkup - CatalogRef.DiscountsMarkups - - discount (mark-up) for which verification is performed
// 
// Returns:
//  Boolean - True , used
Function ThisIsDiscountForBonusPoints(DiscountMarkup) Export
	
	If Not ValueIsFilled(DiscountMarkup) Then
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CASE
	|		WHEN
	|			DiscountsMarkups.DiscountApplicationMethod = VALUE(Enum.DiscountMarkupApplicationMethods.GrantBonusPoints)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsDiscountForBonusPoints
	|FROM
	|	Catalog.DiscountsMarkups AS DiscountsMarkups
	|WHERE
	|	DiscountsMarkups.Ref = &DiscountMarkup";
	
	Query.SetParameter("DiscountMarkup", DiscountMarkup);
	
	Result = Query.Execute().Unload();
	
	Return Result[0].ThisIsDiscountForBonusPoints;
	
EndFunction

// Calculates discounts based on the completed work report.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  InputParameters - Structure - structure with properties:
//   * OnlyPreliminaryCalculation - Boolean - Only a preliminary calculation.
//   * ApplyToObject - Boolean - Apply to an object.
//   * RestoreManagedDiscounts - Boolean - Managed to restore discounts (markups).
//   * ManagedDiscounts - Array - Managed discounts (mark-UPS).
//
// Returns:
//  Structure - structure with properties:
//   * DiscountTree - See CreateDiscountTree
//   * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//   * CalculationParameters - Structure - Structure of calculation parameters.
//
Function CalculateActOfWorkPerformed(Object, InputParameters)
	
	SetPrivilegedMode(True);
	
	FillInCommunicationKeysInTablePart(Object, "Services");
	
	UseSets = GetFunctionalOption("UseSets");
	
	// Processing of the tabular part of the "Services".
	GoodsTable = Object.Services.Unload(
		,
		"ConnectionKey,
		|ProductsInSet,
		|ItemVariantOfSet,
		|Products,
		|Characteristic,
		|PriceKind,
		|Count,
		|Price");
	GoodsTable.Columns.Add("Package",           New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	GoodsTable.Columns.Add("Series",              New TypeDescription("CatalogRef.ItemsBatches"));
	GoodsTable.Columns.Add("NumberOfPackages", New TypeDescription("Number"));
	For Each TSRow In GoodsTable Do
		TSRow.NumberOfPackages = TSRow.Count;
	EndDo;
	
	// Processing of the "Goods" tabular part.
	QueryText =
	"SELECT
	|	Goods.ConnectionKey            AS ConnectionKey,
	|	&SetFields,
	|	Goods.Products         AS Products,
	|	Goods.Characteristic       AS Characteristic,
	|	Goods.Package             AS Package,
	|	Goods.Series                AS Series,
	|	&Warehouse                      AS Warehouse,
	|	Goods.PriceKind              AS PriceKind,
	|	Goods.Count           AS Count,
	|	Goods.NumberOfPackages   AS NumberOfPackages,
	|	Goods.Price                             AS Price,
	|	Goods.Price * Goods.NumberOfPackages AS Sum
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ConnectionKey,
	|	&TableFields,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	Table.Series,
	|	Table.Warehouse,
	|	Table.PriceKind,
	|	CatalogProducts.PriceGroup AS PriceGroup,
	|	Table.Count,
	|	Table.NumberOfPackages,
	|	Table.Price,
	|	Table.Sum
	|,&TempTableName
	|FROM
	|	TTProducts_1 AS Table
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = Table.Products
	|		,&Join
	|; SELECT &RequestSets
	|";
	
	QueryOptions = New Structure;
	QueryOptions.Insert("Goods", GoodsTable);
	QueryOptions.Insert("Warehouse", Catalogs.Warehouses.EmptyRef());
	DataOnProductsAndSets = DataOnProductsAndSets(QueryText, QueryOptions, UseSets);
	
	DiscountsMarkups = DiscountMarginsForServices(
		Object.Date,
		Object.Terms,
		Object.LoyaltyCard);
	
	CalculationParameters = CalculationParameters();
	CalculationParameters.DiscountsMarkups = DiscountsMarkups;
	CalculationParameters.Partner       = Object.Partner;
	CalculationParameters.Terms    = Object.Terms;
	CalculationParameters.Recorder   = Object.Ref;
	
	// For the discount "For the form of payment".
	CalculationParameters.PaymentMethod = Object.PaymentMethod;
	
	// For a discount "For the time of sale".
	CalculationParameters.WeekDay   = Enums.WeekDays.Get(WeekDay(Object.Date) - 1);
	CalculationParameters.CurrentTime = GetCurObjectTime(Object);
	CalculationParameters.CurrentDate  = GetCurDateOfPlace(Object);
	
	// For the discount "For compliance with the payment schedule".
	CalculationParameters.PaymentSchedule = Undefined;
	
	// Loyalty card
	CalculationParameters.LoyaltyCard = Object.LoyaltyCard;
	
	CalculationParameters.Goods                     = DataOnProductsAndSets.Goods;
	CalculationParameters.DocumentCurrency            = Object.Currency;
	CalculationParameters.ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	CalculationParameters.BaseCurrency              = SettingsValueCached.DefaultBaseCurrency();
	CalculationParameters.User               = Object.Manager;
	CalculationParameters.Object                     = Object;
	
	PrepareDataOnSelectedManagedDiscounts(Object, CalculationParameters, InputParameters);
	AppliedDiscountsMarkups = CalculateDiscountMarkUpTree(CalculationParameters, InputParameters);
	
	If UseSets And Not InputParameters.OnlyPreliminaryCalculation Then
		DistributeKitDiscountsByComponents(AppliedDiscountsMarkups, DataOnProductsAndSets.MatchingKeys, GoodsTable);
	EndIf;
	
	If InputParameters.ApplyToObject Then
		
		ApplyResultOfCalculationToActOfWorkPerformed(Object, AppliedDiscountsMarkups);
		
	EndIf;
	
	Return AppliedDiscountsMarkups;
	
EndFunction

// Calculates discounts based on the KKM receipt.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  InputParameters - Structure - structure with properties:
//   * OnlyPreliminaryCalculation - Boolean - Only a preliminary calculation.
//   * ApplyToObject - Boolean - Apply to an object.
//   * RestoreManagedDiscounts - Boolean - Managed to restore discounts (markups).
//   * ManagedDiscounts - Array - Managed discounts (mark-UPS).
//
// Returns:
//  Structure - structure with properties:
//   * DiscountTree - See CreateDiscountTree
//   * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//   * CalculationParameters - Structure - Structure of calculation parameters.
//
Function CalculateByReceiptCashRegister(Object, InputParameters)
	
	SetPrivilegedMode(True);
	
	FillInCommunicationKeysInTablePart(Object, "Goods");
	
	UseSets = GetFunctionalOption("UseSets");
	
	// Processing of the "Goods" tabular part.
	QueryText =
	"SELECT
	|	Goods.ConnectionKey          AS ConnectionKey,
	|	&SetFields,
	|	Goods.Products       AS Products,
	|	Goods.Characteristic     AS Characteristic,
	|	Goods.Package           AS Package,
	|	Goods.Series              AS Series,
	|	&Warehouse                    AS Warehouse,
	|	&PriceKind                  AS PriceKind,
	|	Goods.Count         AS Count,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Price                             AS Price,
	|	Goods.Price * Goods.NumberOfPackages AS Sum
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ConnectionKey,
	|	&TableFields,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	Table.Series,
	|	Table.Warehouse,
	|	Table.PriceKind,
	|	CatalogProducts.PriceGroup AS PriceGroup,
	|	Table.Count,
	|	Table.NumberOfPackages,
	|	Table.Price,
	|	Table.Sum
	|,&TempTableName
	|FROM
	|	TTProducts_1 AS Table
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = Table.Products
	|		,&Join
	|; SELECT &RequestSets
	|";
	
	GoodsTable = Object.Goods.Unload();
	
	QueryOptions = New Structure;
	QueryOptions.Insert("Goods", GoodsTable);
	QueryOptions.Insert("PriceKind", Object.PriceKind);
	QueryOptions.Insert("Warehouse", Object.Warehouse);
	DataOnProductsAndSets = DataOnProductsAndSets(QueryText, QueryOptions, UseSets);
	
	DiscountsMarkups = DiscountMarkupsForRetailers(
		Object.Date,
		Object.Warehouse,
		Object.LoyaltyCard);
	
	CalculationParameters = CalculationParameters();
	CalculationParameters.DiscountsMarkups = DiscountsMarkups;
	CalculationParameters.Partner       = Object.Partner;
	CalculationParameters.Terms    = Undefined;
	CalculationParameters.Recorder   = Object.Ref;
	
	// For the discount "For the form of payment".
	CalculationParameters.PaymentMethod = Object.PaymentMethod;
	
	// For a discount "For the time of sale".
	CalculationParameters.WeekDay   = Enums.WeekDays.Get(WeekDay(Object.Date) - 1);
	CalculationParameters.CurrentTime = GetCurObjectTime(Object);
	CalculationParameters.CurrentDate  = GetCurDateOfPlace(Object);
	
	// For the discount "For compliance with the payment schedule".
	CalculationParameters.PaymentSchedule = Undefined;
	
	// Loyalty card
	CalculationParameters.LoyaltyCard = Object.LoyaltyCard;
	
	CalculationParameters.Goods                     = DataOnProductsAndSets.Goods;
	CalculationParameters.DocumentCurrency            = Object.Currency;
	CalculationParameters.ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	CalculationParameters.BaseCurrency              = SettingsValueCached.DefaultBaseCurrency();
	CalculationParameters.User               = Object.Cashier;
	CalculationParameters.Object                     = Object;
	
	PrepareDataOnSelectedManagedDiscounts(Object, CalculationParameters, InputParameters);
	AppliedDiscountsMarkups = CalculateDiscountMarkUpTree(CalculationParameters, InputParameters);
	
	If UseSets And Not InputParameters.OnlyPreliminaryCalculation Then
		DistributeKitDiscountsByComponents(AppliedDiscountsMarkups, DataOnProductsAndSets.MatchingKeys, GoodsTable);
	EndIf;
	
	If InputParameters.ApplyToObject Then
		
		ApplyCalculationResultToCashRegisterReceipt(Object, AppliedDiscountsMarkups);
		
	EndIf;
	
	Return AppliedDiscountsMarkups;
	
EndFunction

// Performs the calculation of discounts on the return receipt.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  InputParameters - Structure - structure with properties:
//   * OnlyPreliminaryCalculation - Boolean - Only a preliminary calculation.
//   * ApplyToObject - Boolean - Apply to an object.
//   * RestoreManagedDiscounts - Boolean - Managed to restore discounts (markups).
//   * ManagedDiscounts - Array - Managed discounts (mark-UPS).
//
// Returns:
//  Structure - structure with properties:
//   * DiscountTree - See CreateDiscountTree
//   * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//   * CalculationParameters - Structure - Structure of calculation parameters.
//
Function CalculateCashRegisterReturnByReceipt(Object, InputParameters)
	
	SetPrivilegedMode(True);
	
	UseSets = GetFunctionalOption("UseSets");
	
	// Processing of the "Goods" tabular part.
	QueryText =
	"SELECT
	|	Goods.LineNumber        AS ConnectionKey,
	|	&SetFields,
	|	Goods.Products       AS Products,
	|	Goods.Characteristic     AS Characteristic,
	|	Goods.Package           AS Package,
	|	Goods.Series              AS Series,
	|	&Warehouse                    AS Warehouse,
	|	&PriceKind                  AS PriceKind,
	|	Goods.Count         AS Count,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Price                             AS Price,
	|	Goods.Price * Goods.NumberOfPackages AS Sum
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ConnectionKey,
	|	&TableFields,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	Table.Series,
	|	Table.Warehouse,
	|	Table.PriceKind,
	|	CatalogProducts.PriceGroup AS PriceGroup,
	|	Table.Count,
	|	Table.NumberOfPackages,
	|	Table.Price,
	|	Table.Sum
	|,&TempTableName
	|FROM
	|	TTProducts_1 AS Table
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = Table.Products
	|		,&Join
	|; SELECT &RequestSets
	|";
	
	GoodsTable = Object.Goods.Unload();
	
	QueryOptions = New Structure;
	QueryOptions.Insert("Goods", GoodsTable);
	QueryOptions.Insert("PriceKind", Object.PriceKind);
	QueryOptions.Insert("Warehouse", Object.Warehouse);
	DataOnProductsAndSets = DataOnProductsAndSets(QueryText, QueryOptions, UseSets);
	
	DiscountsMarkups = DiscountMarkupsForRetailers(
		Object.Date,
		Object.Warehouse,
		Object.LoyaltyCard);
	
	CalculationParameters = CalculationParameters();
	CalculationParameters.DiscountsMarkups = DiscountsMarkups;
	CalculationParameters.Partner       = Object.Partner;
	CalculationParameters.Terms    = Undefined;
	CalculationParameters.Recorder   = Object.Ref;
	
	// For a discount "For the time of sale".
	CalculationParameters.WeekDay   = Enums.WeekDays.Get(WeekDay(Object.Date) - 1);
	CalculationParameters.CurrentTime = GetCurObjectTime(Object);
	CalculationParameters.CurrentDate  = GetCurDateOfPlace(Object);
	
	// For the discount "For compliance with the payment schedule".
	CalculationParameters.PaymentSchedule = Undefined;
	
	// Loyalty card
	CalculationParameters.LoyaltyCard = Object.LoyaltyCard;
	
	CalculationParameters.Goods                     = DataOnProductsAndSets.Goods;
	CalculationParameters.DocumentCurrency            = Object.Currency;
	CalculationParameters.ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	CalculationParameters.BaseCurrency              = SettingsValueCached.DefaultBaseCurrency();
	CalculationParameters.User               = Object.Cashier;
	CalculationParameters.Object                     = Object;
	
	CalculationParameters.Insert("ManagedDiscounts", New Array);
	Messages = New ValueTable;
	Messages.Columns.Add("DiscountMarkup",  New TypeDescription("CatalogRef.DiscountsMarkups"));
	Messages.Columns.Add("RemindLater", New TypeDescription("Boolean"));
	Messages.Indexes.Add("DiscountMarkup");
	CalculationParameters.Insert("Messages", Messages);
	
	AppliedDiscountsMarkups = New Structure;
	AppliedDiscountsMarkups.Insert("DiscountTree" ,New ValueTree);
	AppliedDiscountsMarkups.Insert("TableDiscountsMarkups" ,New ValueTable);
	AppliedDiscountsMarkups.Insert("CalculationParameters" ,CalculationParameters);

	Return AppliedDiscountsMarkups;
	
EndFunction

// The procedure applies the discount calculation result to the document.
// Called from document forms.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  AppliedDiscountsMarkups - Structure - structure with properties:
//    * DiscountTree - ValueTree - Tree of discounts (markups).
//    * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//    * CalculationParameters - Structure - Structure of calculation parameters.
//
Procedure ApplyCalculationResultToCustomerOrder(Object, AppliedDiscountsMarkups)
	
	UsePaymentWithBonusPoints = UseLoyaltyPrograms(Object.LoyaltyCard);
	AdditionalParameters = New Structure("UsePaymentWithBonusPoints", UsePaymentWithBonusPoints);
	
	ApplyCalculationResultToObject(Object, "Goods", AppliedDiscountsMarkups, True,,,AdditionalParameters);
	
	ApplyCalculationResultForBonusPoints(Object, "Goods", AppliedDiscountsMarkups, UsePaymentWithBonusPoints);
	
EndProcedure

// Use bonus loyalty programs.
// 
// Parameters:
//  LoyaltyCard - CatalogRef.LoyaltyCards - Loyalty Card
// 
// Returns:
//  Boolean - Use bonus loyalty programs
Function UseLoyaltyPrograms(LoyaltyCard) Export
	
	If Not GetFunctionalOption("UseLoyaltyPrograms") 
		Or Not ValueIsFilled(LoyaltyCard) Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	|	LoyaltyCards.Owner.LoyaltyProgram AS LoyaltyProgram
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|WHERE
	|	LoyaltyCards.Ref = &LoyaltyCard";
	
	Query.SetParameter("LoyaltyCard", LoyaltyCard);
	
	BonusProgramIsFull = False;
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		BonusProgramIsFull = ValueIsFilled(Selection.LoyaltyProgram);
	EndIf;
	
	Return BonusProgramIsFull;
	
EndFunction

// The procedure applies the discount calculation result to the document.
// Called from document forms.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  AppliedDiscountsMarkups - Structure - structure with properties:
//    * DiscountTree - ValueTree - Tree of discounts (markups).
//    * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//    * CalculationParameters - Structure - Structure of calculation parameters.
//
Procedure ApplyCalculationResultToReturnOfGoodsFromCustomer(Object, AppliedDiscountsMarkups)
	
	UsePaymentWithBonusPoints = UseLoyaltyPrograms(Object.LoyaltyCard);
	AdditionalParameters = New Structure("UsePaymentWithBonusPoints", UsePaymentWithBonusPoints);

	ApplyCalculationResultToObject(Object, "SubstituteGoods", AppliedDiscountsMarkups, True, , , AdditionalParameters);
	
	ApplyCalculationResultForBonusPoints(Object, "SubstituteGoods", AppliedDiscountsMarkups, UsePaymentWithBonusPoints);

	
EndProcedure

// The procedure applies the discount calculation result to the document.
// Called from document forms.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  AppliedDiscountsMarkups - Structure - with properties:
//    * DiscountTree - ValueTree - Tree of discounts (markups).
//    * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//    * CalculationParameters - Structure - Structure of calculation parameters.
//
Procedure ApplyCalculationResultToCommercialOfferToClient(Object, AppliedDiscountsMarkups)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ColumnNameQuantity",             "Count");
	DiscountsMarkupsServer.ApplyCalculationResultToObject(Object, "Goods", AppliedDiscountsMarkups, True,,,AdditionalParameters);
	
EndProcedure

// The procedure applies the discount calculation result to the document.
// Called from document forms.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  AppliedDiscountsMarkups - Structure - structure with properties:
//    * DiscountTree - ValueTree - Tree of discounts (markups).
//    * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//    * CalculationParameters - Structure - Structure of calculation parameters.
//
Procedure ApplyCalculationResultToSaleOfGoodsServices(Object, AppliedDiscountsMarkups, SalesInExcessOfOrder)
	
	UsePaymentWithBonusPoints = UseLoyaltyPrograms(Object.LoyaltyCard);
	AdditionalParameters = New Structure("UsePaymentWithBonusPoints", UsePaymentWithBonusPoints);

	ApplyCalculationResultToObject(Object, "Goods", AppliedDiscountsMarkups, True, True, SalesInExcessOfOrder, AdditionalParameters);
	
	ApplyCalculationResultForBonusPoints(Object, "Goods", AppliedDiscountsMarkups, UsePaymentWithBonusPoints, SalesInExcessOfOrder);
	
EndProcedure

// The procedure applies the discount calculation result to the document.
// Called from document forms.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  AppliedDiscountsMarkups - Structure - structure with properties:
//    * DiscountTree - ValueTree - Tree of discounts (markups).
//    * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//    * CalculationParameters - Structure - Structure of calculation parameters.
//
Procedure ApplyResultOfCalculationToActOfWorkPerformed(Object, AppliedDiscountsMarkups)
	
	UsePaymentWithBonusPoints = UseLoyaltyPrograms(Object.LoyaltyCard);
	AdditionalParameters = New Structure("UsePaymentWithBonusPoints", UsePaymentWithBonusPoints);

	ApplyCalculationResultToObject(Object, "Services", AppliedDiscountsMarkups, True, True,,AdditionalParameters);
	
	ApplyCalculationResultForBonusPoints(Object, "Services", AppliedDiscountsMarkups, UsePaymentWithBonusPoints);
	
EndProcedure

// The procedure applies the discount calculation result to the document.
// Called from document forms.
//
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  AppliedDiscountsMarkups - Structure - structure with properties:
//    * DiscountTree - ValueTree - Tree of discounts (markups).
//    * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//    * CalculationParameters - Structure - Structure of calculation parameters.
//
Procedure ApplyCalculationResultToCashRegisterReceipt(Object, AppliedDiscountsMarkups)
	
	AdditionalParameters = New Structure("UsePaymentWithBonusPoints", Object.UsePaymentWithBonusPoints);
	ApplyCalculationResultToObject(Object, "Goods", AppliedDiscountsMarkups, False,,,AdditionalParameters);
	
	ApplyCalculationResultForBonusPoints(Object, "Goods", AppliedDiscountsMarkups, Object.UsePaymentWithBonusPoints);
	
EndProcedure

// Apply the result of the calculation of bonus points.
// 
// Parameters:
//  Object - DocumentObject, FormDataStructure, DocumentObject.CustomerInvoice - Object
//  TSName  - String - name of the table part for calculating discounts
//  AppliedDiscountsMarkups - String, Structure - Applied discounts margins:
// * DiscountTree - ValueTree -
// * TableDiscountsMarkups - ValueTable -
// * CalculationParameters - Structure -
//  UsePaymentWithBonusPoints - Boolean, Structure - Use payment with bonus points:
// * DiscountTree - ValueTree -
// * TableDiscountsMarkups - ValueTable -
// * CalculationParameters - Structure -
//  SalesInExcessOfOrder - Boolean -
Procedure ApplyCalculationResultForBonusPoints(Object, 
													TSName, 
													AppliedDiscountsMarkups, 
													UsePaymentWithBonusPoints = False, 
													SalesInExcessOfOrder = False)
	
	If TypeOf(Object) = Type("Structure") Then
		Return;
	EndIf;
	
	If TypeOf(Object.Ref) = Type("DocumentRef.CashRegisterReceipt") Then
		BonusPointsTable = Object.BonusPoints;
		UseCommunicationKey = False;
	Else
		BonusPointsTable = Object.BonusPointAccrual;
		UseCommunicationKey = True;
	EndIf;

	If Object.Partner = Catalogs.Partners.RetailCustomer 
		Or Not SalesInExcessOfOrder Then
		
		If BonusPointsTable.Count() > 0 Then
			BonusPointsTable.Clear();
		EndIf;
		
		If Object.Partner = Catalogs.Partners.RetailCustomer Then
			Return;
		EndIf;
		
	EndIf;
	
	EarnedBonusPoints = BonusPointsServer.BonusPointsTable(AppliedDiscountsMarkups.TableDiscountsMarkups, Object.Date);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ISNULL(LoyaltyCards.Owner.LoyaltyProgram.DoNotAccruePointsWhenPayingWithBonuses, FALSE) AS DoNotAccruePointsWhenPayingWithBonuses
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|WHERE
	|	LoyaltyCards.Ref = &LoyaltyCard";
	
	Query.SetParameter("LoyaltyCard", Object.LoyaltyCard);
	
	SimultaneousDebitingAndAccrualIsUsed = False;
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		SimultaneousDebitingAndAccrualIsUsed = Not Selection.DoNotAccruePointsWhenPayingWithBonuses;
	EndIf;
	
	BonusPoints = New ValueTable;
	If UseCommunicationKey Then
		BonusPoints.Columns.Add("ConnectionKey",                   New TypeDescription("Number"));
	EndIf;
	BonusPoints.Columns.Add("LoyaltyProgram", New TypeDescription("CatalogRef.LoyaltyPrograms"));
	BonusPoints.Columns.Add("AccrualDate",              TMCommonUse.GetDescriptionOfDateTypes(DateFractions.DateTime));
	BonusPoints.Columns.Add("DateOfDeduction",                TMCommonUse.GetDescriptionOfDateTypes(DateFractions.DateTime));
	BonusPoints.Columns.Add("AmountOfBonusPoints",         TMCommonUse.MoneyFieldTypeDescription());
	
	For Each TSRow In Object[TSName] Do
		If SalesInExcessOfOrder And TSRow.RowCode > 0 Then 
			Continue;
		EndIf;
		
		If UsePaymentWithBonusPoints And (SimultaneousDebitingAndAccrualIsUsed Or TSRow.AmountOfBonusPointsToDeduction = 0)
			Or Not UsePaymentWithBonusPoints Then 
			
			Accrued = 0;
			FoundRows = EarnedBonusPoints.FindRows(New Structure("ConnectionKey", TSRow.ConnectionKey));
			For Each ScoringLine In FoundRows Do
				
				NewRow = BonusPoints.Add();
				FillPropertyValues(NewRow, ScoringLine);
				
				// Conversion of accrued points from the currency of the document into points.
				NewCurrency = ScoringLine.BonusConversionCurrency;
				StructureOfNewCurrencyRates = AppliedDiscountsMarkups.CalculationParameters.ExchangeRates.Find(NewCurrency, "Currency");
				CurrentCurrency = Object.Currency;
				StructureOfCurExchangeRates = AppliedDiscountsMarkups.CalculationParameters.ExchangeRates.Find(CurrentCurrency, "Currency");
				
				Accrued = Accrued + ScoringLine.AmountOfBonusPoints;
				
				NewRow.AmountOfBonusPoints = ProcessingOfExchangeRatesTM.ConvertAtRate(NewRow.AmountOfBonusPoints,
					StructureOfCurExchangeRates,
					StructureOfNewCurrencyRates) / ScoringLine.ConversionRateOfBonusesIntoCurrency;
				
			EndDo;
			
			TSRow.AmountOfEarnedBonusPointsInCurrency = Accrued;
			
		Else
			
			TSRow.AmountOfEarnedBonusPointsInCurrency = 0;
			
		EndIf;
	EndDo;
	
	If UseCommunicationKey Then
		BonusPoints.GroupBy("ConnectionKey, LoyaltyProgram, AccrualDate, DateOfDeduction", "AmountOfBonusPoints");
	Else
		BonusPoints.GroupBy("LoyaltyProgram, AccrualDate, DateOfDeduction", "AmountOfBonusPoints");
	EndIf;
	
	For Each TSRow In BonusPoints Do
		NewRow = BonusPointsTable.Add();
		FillPropertyValues(NewRow, TSRow);
	EndDo;
	
EndProcedure

#EndRegion

#Region DiscountMarkUpCalculationFunctionsOnDiscountMarkUpTree

Function GetGroupMultiplicationParent(TreeRow, CalculationParameters)
	
	Result = CalculationParameters.CacheMultiplicationGroups.Get(TreeRow);
	If Result <> Undefined Then
		Return Result;
	EndIf;
	
	If TreeRow.Parent = Undefined Then
		Result = Undefined;
	Else
		
		Parent = TreeRow.Parent;
		TopLevelMultiplicationGroup = GetGroupMultiplicationParent(Parent, CalculationParameters);
		
		If TopLevelMultiplicationGroup = Undefined
			And Parent.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Multiplication Then
			Result = Parent;
		Else
			Result = GetGroupMultiplicationParent(Parent, CalculationParameters);
		EndIf;
		
	EndIf;
	
	CalculationParameters.CacheMultiplicationGroups.Insert(TreeRow, Result);
	
	Return Result;
	
EndFunction

// Parameters:
// 	TreeRow - ValueTreeRow - LongDesc See CreateDiscountTree
// 
Function GetSummaryOfCalculationResult(TreeRow, ConnectionKey, CalculationParameters)
	
	Id = String(TreeRow.Ref.UUID()) + ConnectionKey;
	Sum = CalculationParameters.CacheMultiplicationSum.Get(Id);
	If Sum <> Undefined Then
		Return Sum;
	EndIf;
	
	Sum = 0;
	
	For Each CurStringTree In TreeRow.CalculationResult2 Do
		
		If Not CurStringTree.Valid Then
			Continue;
		EndIf;
		
		If CurStringTree.ConnectionKey <> ConnectionKey Then
			Continue;
		EndIf;
		
		Sum = Sum + CurStringTree.Sum;
		
	EndDo;
	
	CalculationParameters.CacheMultiplicationSum.Insert(Id, Sum);
	
	Return Sum;
	
EndFunction

// The function gets the amount of the applied discount of subordinate groups for the product line, taking into account the discount hierarchy.
//
// Returns:
//	Number - The amount of the discount applied.
//
Function GetAmountOfDiscountsApplied(TreeRows, ConnectionKey, CalculationParameters, IgnoreGroup)
	
	Sum = 0;
	
	For Each TreeRow In TreeRows Do
		If TreeRow.IsFolder Then			
			If TreeRow = IgnoreGroup Then			
				Continue;                              			
			EndIf;
			If TreeRow.Calculated Then
				Sum = Sum + GetSummaryOfCalculationResult(TreeRow, ConnectionKey, CalculationParameters);
			Else
				Sum = Sum + GetAmountOfDiscountsApplied(TreeRow.Rows, ConnectionKey, CalculationParameters, IgnoreGroup);
			EndIf;
		Else
			If TreeRow.Calculated Then
				Sum = Sum + GetSummaryOfCalculationResult(TreeRow, ConnectionKey, CalculationParameters);
			EndIf;
		EndIf;
		
	EndDo;
	
	Return Sum;
	
EndFunction


// The function gets the item price by the type of price specified in the discount parameters.
//
// Returns:
//	Number - the price of the item.
//
Function GetPriceOfProductItemByPriceType(OwnGoods, Parameters, PriceKind)
	
	Price = 0;
	
	Filter = New Structure(
		"Products,
		|Characteristic,
		|PriceKind",
		OwnGoods.Products,
		OwnGoods.Characteristic,
		PriceKind);
	
	ArrayOfPriceStrings = Parameters.ItemsPrices.FindRows(Filter);
	For Each PriceLine In ArrayOfPriceStrings Do
		
		If PriceLine.Package = OwnGoods.Package Then
			Price = PriceLine.Price;
		Else
			
			// Let's bring the price to the price for the packaging of the segment.
			// The price is not rounded to increase accuracy...
			If OwnGoods.NumberOfPackages = 0 Then
				PackagingConversionFactor = 0;
			Else
				PackagingConversionFactor = OwnGoods.Count / OwnGoods.NumberOfPackages;
			EndIf;
			If PriceLine.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef() Then
				Price = PriceLine.Price * PackagingConversionFactor;
			Else
				Price = (PriceLine.Price / PriceLine.PackageFactor) * PackagingConversionFactor;
			EndIf;
			
		EndIf;
		
		Break;
		
	EndDo;
	
	Return Price;
	
EndFunction


// The function performs a Union of the member tables of data.
//
// Returns:
//	ValueTable - combined data table:
//		* ConnectionKey					- Number
//		* Sum						- Number
//		* Details				- ValueTable
//		* AddlOrderingAttribute	- Number
//
Function CombineResultsOfCalculationOfSubordinateRows(TreeRow)
	
	CalculationResult2 = New ValueTable;
	CalculationResult2.Columns.Add("ConnectionKey",                 New TypeDescription("Number"));
	CalculationResult2.Columns.Add("Sum",                     New TypeDescription("Number"));
	CalculationResult2.Columns.Add("Details",               New TypeDescription("ValueTable"));
	CalculationResult2.Columns.Add("AddlOrderingAttribute", New TypeDescription("Number"));
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		If Not SubordinateRow.IsFolder Then // This is a discount, not a group
			
			If Not SubordinateRow.ConditionParameters_.ConditionsAreFulfilled Then
				Continue;
			EndIf;
			
			If SubordinateRow.Managed And Not SubordinateRow.AssignedByUser Then
				Continue;
			EndIf;
			
		EndIf;
		
		FillInDataTableOfSubordinateRows(CalculationResult2, SubordinateRow);
		
	EndDo;
	
	Return CalculationResult2;
	
EndFunction

// The procedure calculates the discount for the joint application group: maximum, minimum, and displacement.
//
Procedure CalculateDiscountsByGroupOfJointApplicationMaximumMinimumDisplacement(TreeRow, Parameters)
	
	VT = EmptyDiscountTableWithDecryption(Parameters);
	
	If TreeRow.OptionOfJointApplicationResultCalculation = Enums.OptionsOfJointApplicationResultCalculation.ByLine Then
		
		CalculationResult2 = CombineResultsOfCalculationOfSubordinateRows(TreeRow);
		If TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Max Then
			CalculationResult2.Sort("ConnectionKey, Sum Desc, AddlOrderingAttribute");
		ElsIf TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Min Then
			CalculationResult2.Sort("ConnectionKey, Sum Asc, AddlOrderingAttribute");
		ElsIf TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Exclusion Then
			CalculationResult2.Sort("ConnectionKey, AddlOrderingAttribute");
		EndIf;
		
		ConnectionKey = Undefined;
		For Each TableRow In CalculationResult2 Do
			
			If TableRow.ConnectionKey <> ConnectionKey Then
				
				NewRow = VT.Add();
				FillPropertyValues(NewRow, TableRow);
				NewRow.Valid = True;
				
				ConnectionKey = TableRow.ConnectionKey;
				
			EndIf;
			
		EndDo;
		
	Else
		
		CalculationResult2 = DataTableOnMethodOfJointApplicationForDocumentAsWhole(TreeRow);
		For Each TableRow In CalculationResult2 Do
			
			NewRow = VT.Add();
			FillPropertyValues(NewRow, TableRow);
			NewRow.Valid = True;
			
		EndDo;
		
	EndIf;
	
	TreeRow.CalculationResult2 = VT;
	
EndProcedure

// The procedure calculates the discount for the joint application group: addition.
//
Procedure CalculateDiscountsByGroupJointApplicationAdditionMultiplication(TreeRow, CalculationParameters)
	
	CalculationResult2 = CombineResultsOfCalculationOfSubordinateRows(TreeRow);
	CalculationResult2.Sort("ConnectionKey");
	
	VT = EmptyDiscountTableWithDecryption(CalculationParameters);
	
	ConnectionKey = Undefined;
	For Each TableRow In CalculationResult2 Do
		
		If TableRow.ConnectionKey <> ConnectionKey Then
			
			NewLineOfVT = VT.Add();
			NewLineOfVT.ConnectionKey = TableRow.ConnectionKey;
			NewLineOfVT.Sum = TableRow.Sum;
			NewLineOfVT.Valid = True;
			
			// Explanation of the discount.
			NewLineOfVT.Details = CalculationParameters.EmptyDecryptionTable.CopyColumns();
			For Each DecryptionString In TableRow.Details Do
				FillPropertyValues(NewLineOfVT.Details.Add(), DecryptionString);
			EndDo;
			
			ConnectionKey = TableRow.ConnectionKey;
			
		Else
			
			NewLineOfVT.Sum = NewLineOfVT.Sum + TableRow.Sum;
			For Each DecryptionString In TableRow.Details Do
				FillPropertyValues(NewLineOfVT.Details.Add(), DecryptionString);
			EndDo;
			
		EndIf;
		
	EndDo;
	
	TreeRow.CalculationResult2 = VT;
	
EndProcedure

// This procedure calculates the discount for a shared application group.
//
Procedure CalculateDiscountsByJointApplicationGroup(TreeRow, CalculationParameters)
	
	If    TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Max
		Or TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Min
		Or TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Exclusion Then
		
		CalculateDiscountsByGroupOfJointApplicationMaximumMinimumDisplacement(TreeRow, CalculationParameters);
		
	ElsIf TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Multiplication
		  Or TreeRow.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Addition Then
		
		CalculateDiscountsByGroupJointApplicationAdditionMultiplication(TreeRow, CalculationParameters);
		
	EndIf;
	
	TreeRow.Calculated = True;
	
EndProcedure // Calculate the size of a group of place applications()

Function ProductLinesForDistribution(TreeRow, CalculationParameters)
	
	If TreeRow.ConditionParameters_.ThereAreConditionsOnLine Then
		Goods = New Array;
		For Each TSRow In TreeRow.ConditionParameters_.ConditionsByLine.ConditionVerificationTable Do
			GoodsTable = CalculationParameters.Goods;//ValueTable
			Goods.Add(GoodsTable.Find(TSRow.ConnectionKey, "ConnectionKey"));
		EndDo;
	Else
		Goods = CalculationParameters.Goods;
	EndIf;
	
	Return Goods;
	
EndFunction

Function LineBalance_(TreeRow, OwnGoods, CalculationParameters, ThisIsMultiplication = True)
	
	If ThisIsMultiplication Then
		
		GroupMultiplication = GetGroupMultiplicationParent(TreeRow, CalculationParameters);
		
		IgnoreGroup = GetIgnoreGroup(TreeRow, GroupMultiplication);
		
		If GroupMultiplication <> Undefined Then
			AmountOfDiscountApplied = Round(GetAmountOfDiscountsApplied(GroupMultiplication.Rows, OwnGoods.ConnectionKey, CalculationParameters, IgnoreGroup), 2);
		Else
			AmountOfDiscountApplied = 0;
		EndIf;		
	
		Sum = OwnGoods.Sum - AmountOfDiscountApplied;
		If Sum < 0 Then
			Sum = 0;
		EndIf;
		
	Else
		Sum = OwnGoods.Sum;
	EndIf;
	
	Return Sum;
	
EndFunction

Function GetIgnoreGroup(Val TreeRow, Val GroupMultiplication)
	
	Var ParentGroup2;
	
	ParentGroup2 = TreeRow.Parent;
	If Not (GroupMultiplication <> ParentGroup2 And 
		(ParentGroup2.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Max
		Or ParentGroup2.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Min
		Or ParentGroup2.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Exclusion)) Then
		
		ParentGroup2 = Undefined;
		
	EndIf;
	
	Return ParentGroup2;

EndFunction

Function MultiplicityOfExecution(TreeRow)
	
	MinimumMultiplicityOfExecution = Undefined;
	Conditions = TreeRow.ConditionParameters_.TableOfConditions.FindRows(New Structure("ScopeOfRestriction", Enums.OptionsOfLimitationAreasOfDiscountsAndMarkups.InDocument));
	For Each ConditionString In Conditions Do
		If ConditionString.MultiplicityOfExecution < 0 Then
			Continue;
		EndIf;
		If MinimumMultiplicityOfExecution = Undefined Or ConditionString.MultiplicityOfExecution < MinimumMultiplicityOfExecution Then
			MinimumMultiplicityOfExecution = ConditionString.MultiplicityOfExecution;
		EndIf;
	EndDo;
	If MinimumMultiplicityOfExecution = Undefined Then
		If TreeRow.ConditionParameters_.ConditionsAreFulfilled Then
			MinimumMultiplicityOfExecution = 1;
		Else
			MinimumMultiplicityOfExecution = 0;
		EndIf;
	EndIf;
	If Not TreeRow.UseMultiplier Then
		If MinimumMultiplicityOfExecution > 0 Then
			MinimumMultiplicityOfExecution = 1;
		EndIf;
	EndIf;
	
	Return MinimumMultiplicityOfExecution;
	
EndFunction

Function DiscountMarkupValue(TreeRow, TSRow, CalculationParameters)
	
	DiscountMarkupValue = TreeRow.DiscountMarkupValue;
	
	If CalculationParameters.UsePriceGroups Then
		ClarificationOfTheValueOfTheDiscountMarkUp = CalculationParameters.ClarificationOfTheValueOfTheDiscountMarkUp.Get(TreeRow.Ref);
		If ClarificationOfTheValueOfTheDiscountMarkUp <> Undefined Then
			For Each Refinement In ClarificationOfTheValueOfTheDiscountMarkUp Do
				If Refinement.Key = TSRow.PriceGroup Then
					DiscountMarkupValue = Refinement.Value;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Return DiscountMarkupValue;
	
EndFunction


Function ConvertAmountToBonuses(TreeRow, Sum, CalculationParameters)
	
	Value = Sum;
	
	If TreeRow.DiscountApplicationMethod = Enums.DiscountMarkupApplicationMethods.GrantBonusPoints Then
		
		NewCurrency = TreeRow.BonusConversionCurrency;
		StructureOfNewCurrencyRates = CalculationParameters.ExchangeRates.Find(NewCurrency, "Currency");
		CurrentCurrency = CalculationParameters.DocumentCurrency;
		StructureOfCurExchangeRates = CalculationParameters.ExchangeRates.Find(CurrentCurrency, "Currency");
		
		Value = ProcessingOfExchangeRatesTM.ConvertAtRate(Sum * TreeRow.ConversionRateOfBonusesIntoCurrency,
			StructureOfNewCurrencyRates,
			StructureOfCurExchangeRates);
		
	EndIf;
	
	Return Value;
	
EndFunction

Function GetDiscountTranscript(TreeRow, Sum, CalculationParameters, ThisIsMessage = False)
	
	Details = CalculationParameters.EmptyDecryptionTable.CopyColumns();
	
	DecryptionString = Details.Add();
	DecryptionString.DiscountMarkup = TreeRow.Ref;
	DecryptionString.Sum         = Sum;
	DecryptionString.ThisIsMessage  = ThisIsMessage;
	
	Return Details;
	
EndFunction


Function CostOfCheapestGoods(Count, Goods)
	
	TableOfGoodsValues = New ValueTable;
	TableOfGoodsValues.Columns.Add("Price", New TypeDescription("Number"));
	TableOfGoodsValues.Columns.Add("Count", New TypeDescription("Number"));
	For Each OwnGoods In Goods Do
		
		If OwnGoods.Count = 0 Then
			Continue;
		EndIf;
		
		NewRow = TableOfGoodsValues.Add();
		NewRow.Price       = OwnGoods.Sum / OwnGoods.Count;
		NewRow.Count = OwnGoods.Count;
		
	EndDo;
	TableOfGoodsValues.Sort("Price Asc");
	
	Cost = 0;
	For Iteration = 1 To Count Do
		For Each TSRow In TableOfGoodsValues Do
			If TSRow.Count > 0 Then
				TSRow.Count = TSRow.Count - 1;
				Cost = Cost + TSRow.Price;
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	Return Cost;
	
EndFunction

Procedure ApplyDiscountValueToProduct(TreeRow, DiscountAmount, OwnGoods, CalculationResult2, CalculationParameters) Export
	
	NewRow           = CalculationResult2.Add();
	NewRow.ConnectionKey = OwnGoods.ConnectionKey;
	NewRow.Valid = True;
	
	If TreeRow.Managed And Not TreeRow.AssignedByUser Then
		NewRow.Valid = False;
	EndIf;
	
	// If the discount on this line is not valid, we skip it.
	If TreeRow.ConditionParameters_.ThereAreConditionsOnLine
		And TreeRow.ConditionParameters_.LineCodes.Find(OwnGoods.ConnectionKey) = Undefined Then
		NewRow.Valid = False;
	EndIf;
	
	
	NewRow.Sum = ConvertAmountToBonuses(TreeRow, DiscountAmount, CalculationParameters);
	
	NewRow.Details = GetDiscountTranscript(TreeRow, NewRow.Sum, CalculationParameters);
	
EndProcedure

Procedure DistributeDiscountValueForProducts(TreeRow, DiscountAmount, Goods, CalculationResult2, CalculationParameters) Export
	
	DiscountAmountForDistribution = DiscountAmount;
	
	// Calculation of the total amount of goods.
	TotalAmountOfGoods = 0;
	For Each OwnGoods In Goods Do
		
		Sum = LineBalance_(TreeRow, OwnGoods, CalculationParameters);
		TotalAmountOfGoods = TotalAmountOfGoods + Sum;
		
	EndDo;
	
	// Distribution of discounts on segment products.
	For Each OwnGoods In Goods Do
		
		// Calculation of the discount amount.
		Sum = LineBalance_(TreeRow, OwnGoods, CalculationParameters);
		
		If TotalAmountOfGoods <> 0 Then
			DiscountAmount = Round(Sum * (DiscountAmountForDistribution / TotalAmountOfGoods), 2);
		Else
			DiscountAmount = 0;
		EndIf;
		
		ApplyDiscountValueToProduct(TreeRow, DiscountAmount, OwnGoods, CalculationResult2, CalculationParameters);
		
		DiscountAmountForDistribution = DiscountAmountForDistribution - DiscountAmount;
		TotalAmountOfGoods = TotalAmountOfGoods - Sum;
		
	EndDo;
	
EndProcedure


// The procedure calculates the discount of the discount tree.
//
Procedure CalculateDiscount(TreeRow, CalculationParameters)
	
	Goods = ProductLinesForDistribution(TreeRow, CalculationParameters);
	
	CalculationResult2 = EmptyDiscountTableWithDecryption(CalculationParameters);
	
	If TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Percent Then
		
		ThisIsMultiplication = TreeRow.ApplyMultiplicationWithinParentGroup;
		
		For Each OwnGoods In Goods Do
			
			If TreeRow.ConditionParameters_.ConditionsAreFulfilled Then
				Sum = DiscountMarkupValue(TreeRow, OwnGoods, CalculationParameters) / 100 * LineBalance_(TreeRow, OwnGoods, CalculationParameters, ThisIsMultiplication);
			Else
				Sum = 0;
			EndIf; 
			
			ApplyDiscountValueToProduct(TreeRow, Sum, OwnGoods, CalculationResult2, CalculationParameters);
			
		EndDo;
		
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Sum Then
		
		DiscountAmount = TreeRow.DiscountMarkupValue * MultiplicityOfExecution(TreeRow);
		
		DistributeDiscountValueForProducts(TreeRow, DiscountAmount, Goods, CalculationResult2, CalculationParameters);
		
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.DiscountMarkupAsAmountForEachRow Then
		
		MultiplicityOfExecution = MultiplicityOfExecution(TreeRow);
		
		For Each OwnGoods In Goods Do
			
			DiscountAmount = DiscountMarkupValue(TreeRow, OwnGoods, CalculationParameters) * MultiplicityOfExecution;
			
			ApplyDiscountValueToProduct(TreeRow, DiscountAmount, OwnGoods, CalculationResult2, CalculationParameters);
			
		EndDo;
		
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.PriceKind Then
		
		For Each OwnGoods In Goods Do
			
			PricePerPackaging = GetPriceOfProductItemByPriceType(OwnGoods, CalculationParameters, TreeRow.PriceKind);
			If PricePerPackaging <> 0 Then
				DiscountAmount = OwnGoods.Sum - OwnGoods.NumberOfPackages * PricePerPackaging;
			Else
				DiscountAmount = 0;
			EndIf;
			
			ApplyDiscountValueToProduct(TreeRow, DiscountAmount, OwnGoods, CalculationResult2, CalculationParameters);
			
		EndDo;
		
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Message
		Or TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.LoyaltyCard Then
		
		For Each OwnGoods In Goods Do
			
			NewRow              = CalculationResult2.Add();
			NewRow.ConnectionKey    = OwnGoods.ConnectionKey;
			NewRow.Valid    = True;
			NewRow.Details  = GetDiscountTranscript(TreeRow, 0, CalculationParameters, True);
			
		EndDo;
		
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Count Then
		
		TableOfIdenticalProducts = New ValueTable;
		TableOfIdenticalProducts.Columns.Add("ConnectionKey",      New TypeDescription("Number"));
		TableOfIdenticalProducts.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
		If TreeRow.ApplyVariants Then
			TableOfIdenticalProducts.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		EndIf;
		TableOfIdenticalProducts.Columns.Add("Count",     New TypeDescription("Number"));
		TableOfIdenticalProducts.Columns.Add("Sum",     New TypeDescription("Number"));
		
		For Each OwnGoods In Goods Do
			FillPropertyValues(TableOfIdenticalProducts.Add(), OwnGoods);
		EndDo;
		
		TableOfIdenticalProductsCopy = TableOfIdenticalProducts.Copy();
		If TreeRow.ApplyVariants Then
			TableOfIdenticalProducts.GroupBy("Products, Characteristic", "Count, Sum");
		Else
			TableOfIdenticalProducts.GroupBy("Products", "Count, Sum");
		EndIf;
		
		Filter = New Structure;
		Filter.Insert("Products");
		If TreeRow.ApplyVariants Then
			Filter.Insert("Characteristic");
		EndIf;
		
		For Each OwnGoods In TableOfIdenticalProducts Do
			
			If OwnGoods.Count <> 0 Then
				MultiplicityOfExecution = Round((OwnGoods.Count / TreeRow.DiscountConditionByQuantity) - 0.5, 0, RoundMode.Round15as20);
			Else
				MultiplicityOfExecution = 0;
			EndIf;
			
			If MultiplicityOfExecution > 0 Then
				
				FillPropertyValues(Filter, OwnGoods);
				ProductLines_2 = TableOfIdenticalProductsCopy.FindRows(Filter);
				
				DiscountAmount = CostOfCheapestGoods(MultiplicityOfExecution * TreeRow.DiscountMarkupValue, ProductLines_2);
				DistributeDiscountValueForProducts(TreeRow, DiscountAmount, ProductLines_2, CalculationResult2, CalculationParameters);
				
			EndIf;
			
		EndDo;
		
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.Gift Then
		
		If ValueIsFilled(TreeRow.GiftSegment) Then
			GiftSegmentProducts = CalculationParameters.ProductsBySegment.FindRows(New Structure("ProductSegment", TreeRow.GiftSegment));
		Else
			GiftSegmentProducts = CalculationParameters.Goods;
		EndIf;
		
		DiscountAmount = CostOfCheapestGoods(MultiplicityOfExecution(TreeRow) * TreeRow.DiscountMarkupValue, GiftSegmentProducts);
		
		DistributeDiscountValueForProducts(TreeRow, DiscountAmount, Goods, CalculationResult2, CalculationParameters);
		
	ElsIf TreeRow.MethodsOfProviding = Enums.MethodsToProvideDiscountsMarkups.RoundDocumentAmount Then
		
		GoodsAmount = 0;
		For Each OwnGoods In Goods Do
			GoodsAmount = GoodsAmount + Round(LineBalance_(TreeRow, OwnGoods, CalculationParameters), 2);
		EndDo;
		
		DiscountAmount = 0;
		If TreeRow.DiscountMarkupValue <= GoodsAmount Then
			
			If ValueIsFilled(TreeRow.RoundingPrecision) Then
				DiscountAmount = GoodsAmount - PriceManagementSystemClientServer.RoundUpPrice(GoodsAmount, TreeRow.RoundingPrecision, TreeRow.RoundOffOption);
			EndIf;
			
			If ValueIsFilled(TreeRow.SmartRounding) Then
				DiscountAmount = GoodsAmount + DiscountAmount - PriceManagementSystemClientServer.ApplyPsychologicalRounding(GoodsAmount, TreeRow.SmartRounding);
			EndIf;
			
		EndIf;
		
		DistributeDiscountValueForProducts(TreeRow, DiscountAmount, Goods, CalculationResult2, CalculationParameters);
		
	ElsIf TypeOf(TreeRow.MethodsOfProviding) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
	
		ExternalDataProcessor = DiscountsMarkupsCached.ExternalDataProcessorObject(TreeRow.MethodsOfProviding);
		SetSafeMode(True);
		CalculationResult2 = ExternalDataProcessor.Calculate(
			TreeRow,
			TreeRow.ExternalDataProcessorParameters.Get(),
			Goods,
			CalculationParameters);
		SetSafeMode(False);
		
	EndIf;
	
	TreeRow.Calculated = True;
	TreeRow.CalculationResult2 = CalculationResult2;
	
EndProcedure

// The procedure recursively traverses the tree and calculates
// discounts from bottom to top: from the subordinate element of the tree to the parent.
//
// Parameters:
// DiscountTree - See CreateDiscountTree
// Parameters - Structure - Structure of calculation parameters.
//
Procedure CalculateDiscountsRecursively(DiscountTree, Parameters)
	
	For Each TreeRow In DiscountTree.Rows Do
		
		If TreeRow.IsFolder Then
			
			CalculateDiscountsRecursively(TreeRow, Parameters);
			
			// Discounts on subordinate elements are calculated.
			// We calculate discounts for the group of joint use (parent).
			CalculateDiscountsByJointApplicationGroup(TreeRow, Parameters);
			
		Else
			
			CalculateDiscount(TreeRow, Parameters);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// The function performs a full calculation of discounts in the tree.
//
// Parameters:
//  DiscountTree - ValueTree - Tree of discounts (markups).
//  CalculationParameters - Structure - Structure of calculation parameters.
//
// Returns:
//  Structure - structure with properties:
//   * DiscountTree - ValueTree - Tree of discounts (markups).
//   * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//   * CalculationParameters - Structure - Structure of calculation parameters.
//
Function CalculateDiscountTree(DiscountTree, CalculationParameters)
	
	CalculateDiscountsRecursively(DiscountTree, CalculationParameters);
	
	// There is only one root group at the top level.
	HasResult = DiscountTree.Rows.Count() > 0;
	
	If HasResult Then
		CalculationResult2 = DiscountTree.Rows[0].CalculationResult2;
	EndIf;
	
	VT = New ValueTable;
	VT.Columns.Add("ConnectionKey",     New TypeDescription("Number"));
	VT.Columns.Add("DiscountMarkup", New TypeDescription("CatalogRef.DiscountsMarkups"));
	VT.Columns.Add("Sum",         New TypeDescription("Number"));
	VT.Columns.Add("ThisIsMessage",  New TypeDescription("Boolean"));
	
	If HasResult Then
		For Each TableRow In CalculationResult2 Do
			For Each DiscountMarkUpLine_ In TableRow.Details Do
				NewRow               = VT.Add();
				NewRow.ConnectionKey     = TableRow.ConnectionKey;
				NewRow.DiscountMarkup = DiscountMarkUpLine_.DiscountMarkup;
				NewRow.Sum         = DiscountMarkUpLine_.Sum;
				NewRow.ThisIsMessage  = DiscountMarkUpLine_.ThisIsMessage;
			EndDo;
		EndDo;
		VT.GroupBy("ConnectionKey, DiscountMarkup, ThisIsMessage", "Sum");
	EndIf;
	
	VT.Columns.Add("RemindLater", New TypeDescription("Boolean"));
	VT.Columns.Add("DiscountApplicationMethod", New TypeDescription("EnumRef.DiscountMarkupApplicationMethods"));
	
	If HasResult Then
		For Each TSRow In VT Do
			DiscountMarkUpLine = DiscountTree.Rows.Find(TSRow.DiscountMarkup, "Ref", True);
			TSRow.DiscountApplicationMethod = DiscountMarkUpLine.DiscountApplicationMethod;
		EndDo;
	EndIf;
	
	SaveDataAboutSelectedManagedDiscounts(VT, CalculationParameters);
	
	ReturnedData = New Structure;
	ReturnedData.Insert("DiscountTree",         DiscountTree);
	ReturnedData.Insert("TableDiscountsMarkups", VT);
	ReturnedData.Insert("CalculationParameters",     CalculationParameters);
	
	Return ReturnedData;
	
EndFunction

// This function calculates discounts (margins) based on the passed parameters.
//
// Parameters:
//  CalculationParameters - See DiscountsMarkupsFillingServer.NewParametersCalculate
//  InputParameters - Structure - Input parameter.
//
// Returns:
//  Structure - structure with properties:
//   * DiscountTree - See CreateDiscountTree
//   * TableDiscountsMarkups - See EmptyDiscountMarkUpTable
//   * CalculationParameters - See DiscountsMarkupsFillingServer.NewParametersCalculate
//
Function CalculateDiscountMarkUpTree(CalculationParameters, InputParameters) Export
	
	UsePriceGroups = GetFunctionalOption("UsePriceGroups");
	
	TempTablesManager = New TempTablesManager;
	
	MainTables = CreateRequestPackage();
	MainTables.Query.TempTablesManager = TempTablesManager;
	
	DeleteTemporaryTables_ = False;
	TransformParameters = False;
	For Each KeyAndValue In CalculationParameters Do
		MainTables.Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	RequestPackageInsertRequestIntoPackage(QueryTemporaryTableProducts(CalculationParameters, MainTables),
		MainTables,
		Undefined,
		DeleteTemporaryTables_,
		TransformParameters);
		
	RequestPackageInsertRequestIntoPackage(RequestExchangeRates(CalculationParameters),              MainTables, "ExchangeRates",              DeleteTemporaryTables_, TransformParameters);
	RequestPackageInsertRequestIntoPackage(RequestDiscountMarkUp(CalculationParameters),           MainTables, "DiscountsMarkups",           DeleteTemporaryTables_, TransformParameters);
	RequestPackageInsertRequestIntoPackage(RequestTSTermsOfService(CalculationParameters), MainTables, "TSDiscountMarkupConditions", DeleteTemporaryTables_, TransformParameters);
	RequestPackageInsertRequestIntoPackage(RequestTermsOfService(CalculationParameters),   MainTables, "DiscountMarkupConditions",   DeleteTemporaryTables_, TransformParameters);
	// For Gifts
	RequestPackageInsertRequestIntoPackage(QueryProductsBySegment(CalculationParameters),       MainTables, "ProductsBySegment",       DeleteTemporaryTables_, TransformParameters);
	// For a special price
	RequestPackageInsertRequestIntoPackage(RequestProductPrice(CalculationParameters),        MainTables, "ItemsPrices",        DeleteTemporaryTables_, TransformParameters);
	If UsePriceGroups Then
		RequestPackageInsertRequestIntoPackage(
			RequestDiscountsMarginsByPriceGroups(CalculationParameters),
			MainTables,
			"RefiningValueOfDiscountMarkUpByPriceGroup",
			DeleteTemporaryTables_, TransformParameters);
	EndIf;
	
	QueryBatchExecute(MainTables);
	
	ExchangeRates = BatchQueriesResultByName("ExchangeRates", MainTables).Unload();
	For Each TSRow In ExchangeRates Do
		If TSRow.CourseNumerator = 0 Then
			Raise StrTemplate(
				NStr("vi = 'Đối với tiền tệ %1 chưa đặt tỷ giá.
				           |Trước khi tính chiết khấu (phụ thu) cần thiết lập tỷ giá hối đoái.';
				           |ru = 'Для валюты %1 не установлен курс.
				           |Перед расчетом скидок (наценок) курсы валют должны быть установлены.';
				           |en = 'Exchange rate is not set for currency %1.
				           |Exchange rates must be set before discount (markup) calculation.'; fa = 'Exchange rate is not set for currency %1.
				           |Exchange rates must be set before discount (markup) calculation.';
				           |it = 'Per la valuta %1 non è stato impostato il tasso di cambio.
				           |Prima di calcolare gli sconti (markup) è necessario impostare i tassi di cambio.';
				           |pl = 'Dla waluty %1 nie jest zainstalowany kurs.
				           |Przed rozliczeniem rabatów (marż) kursy walut powinny być zainstalowane.';
				           |tr = '%1 para birimi için döviz kuru ayarlanmadı.
				           |İndirim/zam hesaplanmadan önce döviz kurları ayarlanmalıdır.'"), TSRow.Currency);
		EndIf;
	EndDo;
	
	Conditions               = BatchQueriesResultByName("TSDiscountMarkupConditions", MainTables).Unload();
	DiscountMarkupConditions = BatchQueriesResultByName("DiscountMarkupConditions", MainTables).Unload();
	DiscountTree          = CreateDiscountTree(MainTables);
	
	DiscountTree.Columns.Add("Calculated", New TypeDescription("Boolean"));
	
	Discounts = DiscountTree.Rows.FindRows(New Structure("IsFolder", False), True);
	
	TableFulfilledConditions = FulfillTermsOfServiceRequests(
		DiscountMarkupConditions,
		Discounts,
		CalculationParameters,
		TempTablesManager);
	CheckConditionsRecursively(DiscountTree, Discounts, Conditions, TableFulfilledConditions);
	
	If InputParameters.OnlyPreliminaryCalculation Then
		
		ReturnedData = New Structure;
		ReturnedData.Insert("DiscountTree",         DiscountTree);
		ReturnedData.Insert("TableDiscountsMarkups", EmptyDiscountMarkUpTable());
		ReturnedData.Insert("CalculationParameters",     CalculationParameters);
		
		Return ReturnedData;
		
	EndIf;
	
	CalculationParameters.Insert("UsePriceGroups", UsePriceGroups);
	CalculationParameters.Insert("ItemsPrices",      BatchQueriesResultByName("ItemsPrices",  MainTables).Unload());
	CalculationParameters.Insert("ProductsBySegment",     BatchQueriesResultByName("ProductsBySegment", MainTables).Unload());
	CalculationParameters.Insert("DiscountMarkupConditions", BatchQueriesResultByName("DiscountMarkupConditions",         MainTables).Unload());
	
	CalculationParameters.Insert("AppliedDiscountsMultiplication", EmptyDiscountMarkUpTable());
	CalculationParameters.Insert("FulfilledConditions",         TableFulfilledConditions);
	CalculationParameters.Insert("ExchangeRates",                 ExchangeRates);
	
	CalculationParameters.Insert("EmptyDiscountTableWithDecryption", EmptyDiscountTableWithDecryption());
	CalculationParameters.Insert("EmptyDecryptionTable",         EmptyDecryptionTable());
	CalculationParameters.Insert("EmptyDiscountMarkUpTable",       EmptyDiscountMarkUpTable());
	
	CalculationParameters.Insert("CacheMultiplicationGroups", New Map);
	CalculationParameters.Insert("CacheMultiplicationSum",  New Map);
	
	If UsePriceGroups Then
		
		CalculationParameters.Insert("ClarificationOfTheValueOfTheDiscountMarkUp", New Map);
		
		RefiningValueOfDiscountMarkUpByPriceGroup = BatchQueriesResultByName(
			"RefiningValueOfDiscountMarkUpByPriceGroup", MainTables).Unload();
		
		CurDiscount = Undefined;
		Clarifications = Undefined;
		
		For Each TSRow In RefiningValueOfDiscountMarkUpByPriceGroup Do
			If CurDiscount <> TSRow.DiscountMarkup Then
				If CurDiscount <> Undefined Then
					CalculationParameters.ClarificationOfTheValueOfTheDiscountMarkUp.Insert(CurDiscount, Clarifications);
				EndIf;
				Clarifications = EmptyTableForSpecifyingDiscountMarkUpValue();
				CurDiscount = TSRow.DiscountMarkup;
			EndIf;
			FillPropertyValues(Clarifications.Add(), TSRow);
		EndDo;
		
		If CurDiscount <> Undefined Then
			CalculationParameters.ClarificationOfTheValueOfTheDiscountMarkUp.Insert(CurDiscount, Clarifications);
		EndIf;
		
	EndIf;
	
	CalculationResult2 = CalculateDiscountTree(DiscountTree, CalculationParameters);
	
	Return CalculationResult2;
	
EndFunction

// The procedure applies the result of calculating discounts (markups) to the item.
// Called from document forms.
// Parameters:
//  Object - DocumentObject, FormDataStructure - The object where you want to calculate discounts (mark-UPS).
//  TSName  - String - name of the table part for calculating discounts
//  AppliedDiscountsMarkups - Structure - structure with properties:
//    * DiscountTree - ValueTree - Tree of discounts (markups).
//    * TableDiscountsMarkups - ValueTable - Table with calculated discounts.
//    * CalculationParameters - Structure - Structure of calculation parameters.
//  CalculateAmountWithVAT - Boolean - 
//  CalculateAmountOfSettlements_1 - Boolean -
//  SalesInExcessOfOrder - Boolean - 
//  AdditionalParameters - Structure - Structure with additional parameters
Procedure ApplyCalculationResultToObject(Object,
                                            TSName,
                                            AppliedDiscountsMarkups,
                                            CalculateAmountWithVAT, 
                                            CalculateAmountOfSettlements_1=False,
                                            SalesInExcessOfOrder = False,
                                            AdditionalParameters = Undefined) Export
	
	If SalesInExcessOfOrder Then
		For Each RowOfDiscount In AppliedDiscountsMarkups.TableDiscountsMarkups Do
			TSRow = Object.DiscountsMarkups.Add();
			FillPropertyValues(TSRow, RowOfDiscount);
		EndDo; 
	Else	
		Object.DiscountsMarkups.Load(AppliedDiscountsMarkups.TableDiscountsMarkups);
	EndIf;
	AutomaticMarkUpDiscounts = AppliedDiscountsMarkups.TableDiscountsMarkups.Copy(New Structure("DiscountApplicationMethod", Enums.DiscountMarkupApplicationMethods.ApplyDuringCalculationOfDiscountsMarkups));
	
	// Filling in discounts in the "Products" tabular part
	AutomaticMarkUpDiscounts.GroupBy("ConnectionKey", "Sum");
	AutomaticMarkUpDiscounts.Indexes.Add("ConnectionKey");
	
	If TSName="Services" Then
		QuantityName = "Count";
	ElsIf TypeOf(AdditionalParameters) = Type("Structure")
		And AdditionalParameters.Property("ColumnNameQuantity") Then
		QuantityName = AdditionalParameters.ColumnNameQuantity;
	Else
		QuantityName = "NumberOfPackages";
	EndIf;
	
	For Each TSRow In Object[TSName] Do
		
		If SalesInExcessOfOrder And TSRow.RowCode > 0 Then 
			Continue;
		EndIf;
		
		TableRow = AutomaticMarkUpDiscounts.Find(TSRow.ConnectionKey, "ConnectionKey");
		If TableRow = Undefined Then
			DiscountMarkupAmount = 0;
		Else
			DiscountMarkupAmount = Round(TableRow.Sum, 2);
		EndIf;
		
		CalculateAmountOfSettlementsByLine = (CalculateAmountOfSettlements_1 And TSRow.DiscountMarkupAmount <> DiscountMarkupAmount);
		
		TSRow.DiscountMarkupAmount = DiscountMarkupAmount;
		
		// Automatic discount application.
		AmountWithoutADiscount = Round(TSRow[QuantityName] * TSRow.Price,2);
		
		If AmountWithoutADiscount <> 0 Then
			TSRow.PercentRateOfManualDiscount = 100 * TSRow.ManualDiscount / AmountWithoutADiscount;
		EndIf;
		
		DiscountAmount = DiscountMarkupAmount + TSRow.ManualDiscount;
		
		UsePaymentWithBonusPoints = False;
		
		If TypeOf(AdditionalParameters) = Type("Structure")
			And AdditionalParameters.Property("UsePaymentWithBonusPoints", UsePaymentWithBonusPoints)
			And UsePaymentWithBonusPoints Then
			DiscountAmount = DiscountAmount + TSRow.AmountOfBonusPointsToDeductionInCurrency;
		EndIf;
		
		TSRow.PercentRateOfAutomaticDiscountMarkup = ?(AmountWithoutADiscount = 0, 0 , 100 * DiscountMarkupAmount / AmountWithoutADiscount);
		
		TSRow.Sum    = AmountWithoutADiscount - ?(DiscountAmount > AmountWithoutADiscount, AmountWithoutADiscount, DiscountAmount);
		TSRow.VATAmount = CalculateVATAmount(TSRow.Sum, TSRow.VATRate, Object);
		
		If CalculateAmountWithVAT Then
			TSRow.AmountIncludingVAT = TSRow.Sum + ?(Object.PriceIncludesVAT, 0, TSRow.VATAmount);
		EndIf;
		
		If CalculateAmountOfSettlementsByLine Then
			TSRow.AmountARAP = 0;
		EndIf;
		
	EndDo;
	
	Object.DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Object[TSName], Object.PriceIncludesVAT);
	Object.DiscountsAreCalculated = True;
	
EndProcedure

#EndRegion

#Region RequestsToPrepareDataForCalculation

// The function generates a query for a table of discount values (markups) by price groups.
//
// Returns:
//	Query - Query
//
Function RequestExchangeRates(CalculationParameters)
	
	Query = New Query(
	"SELECT
	|	RelativeRatesInSlices.Currency    AS Currency,
	|	RelativeRatesInSlices.CourseNumerator AS CourseNumerator,
	|	RelativeRatesInSlices.CourseDenominator AS CourseDenominator
	|INTO ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&CurrentDate, BaseCurrency = &BaseCurrency) AS RelativeRatesInSlices
	|
	|INDEX BY
	|	Currency
	|;
	|
	|////#123456789#//////////////////////////////////////////////////////////
	|SELECT
	|	ExchangeRates.Currency    AS Currency,
	|	ExchangeRates.CourseNumerator AS CourseNumerator,
	|	ExchangeRates.CourseDenominator AS CourseDenominator
	|FROM
	|	ExchangeRates
	|");
	
	Query.Parameters.Insert("CurrentDate", CalculationParameters.CurrentDate);
	Query.Parameters.Insert("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	Return Query;
	
EndFunction

// The function generates a query for the table of current discounts (markups).
//
// Returns:
//	Query - Query
//
Function RequestDiscountMarkUp(CalculationParameters, ExtendedVersion_ = True)
	
	Query = New Query(
	"////#123456789#//////////////////////////////////////////////////////////
	|SELECT
	|	DiscountsMarkups.Ref                    AS Ref,
	|	DiscountsMarkups.AddlOrderingAttribute AS AddlOrderingAttribute,
	|	DiscountsMarkups.JointApplicationOption                  AS JointApplicationOption,
	|	DiscountsMarkups.OptionOfJointApplicationResultCalculation AS OptionOfJointApplicationResultCalculation,
	|	DiscountsMarkups.DeletionMark        AS DeletionMark,
	|	DiscountsMarkups.MethodsOfProviding   AS MethodsOfProviding,
	|	DiscountsMarkups.DiscountApplicationMethod AS DiscountApplicationMethod,
	|	DiscountsMarkups.ApplyMultiplicationWithinParentGroup AS ApplyMultiplicationWithinParentGroup,
	|	&ExtendedVersion_1,
	|	DiscountsMarkups.RoundingPrecision        AS RoundingPrecision,
	|	DiscountsMarkups.RoundOffOption         AS RoundOffOption,
	|	DiscountsMarkups.SmartRounding AS SmartRounding,
	|	DiscountsMarkups.IsFolder                    AS IsFolder,
	|	DiscountsMarkups.Managed                  AS Managed,
	|	CASE
	|		WHEN DiscountsMarkups.Ref IN(&ManagedDiscounts) THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS AssignedByUser,
	|	DiscountsMarkups.PriceKind                           AS PriceKind,
	|	DiscountsMarkups.GiftSegment                   AS GiftSegment,
	|	DiscountsMarkups.ProductSegmentRestrictions    AS ProductSegmentRestrictions,
	|	DiscountsMarkups.UseMultiplier             AS UseMultiplier,
	|	DiscountsMarkups.DiscountConditionByQuantity       AS DiscountConditionByQuantity,
	|	DiscountsMarkups.ItemFilterOption         AS ItemFilterOption,
	|	&ExtendedVersion_2,
	|	DiscountsMarkups.DiscountMarkupCurrency AS DiscountMarkupCurrency
	|FROM
	|	Catalog.DiscountsMarkups AS DiscountsMarkups
	|		,&ExtendedVersion_3
	|	
	|WHERE
	|	DiscountsMarkups.Ref IN(&DiscountsMarkups)
	|
	|ORDER BY
	|	DiscountsMarkups.AddlOrderingAttribute
	|TOTALS BY
	|	DiscountsMarkups.Ref HIERARCHY");
	
	Query.Parameters.Insert("DiscountsMarkups",     CalculationParameters.DiscountsMarkups);
	Query.Parameters.Insert("ManagedDiscounts", CalculationParameters.ManagedDiscounts);
	
	If ExtendedVersion_ Then
		
		Query.Parameters.Insert("DocumentCurrency", CalculationParameters.DocumentCurrency);
		
		Query.Text = StrReplace(Query.Text, "&ExtendedVersion_1,", 
			"CASE
			|		WHEN DiscountsMarkups.DiscountApplicationMethod = VALUE(Enum.DiscountMarkupApplicationMethods.ApplyDuringCalculationOfDiscountsMarkups)
			|			AND (DiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.Sum) OR DiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.DiscountMarkupAsAmountForEachRow))
			|			THEN DiscountsMarkups.DiscountMarkupValue * ISNULL(CurrencyRatesProvision.CourseNumerator, 1) * ISNULL(DocumentExchangeRates.CourseDenominator, 1) / (ISNULL(DocumentExchangeRates.CourseNumerator, 1) * ISNULL(CurrencyRatesProvision.CourseDenominator, 1))
			|		ELSE DiscountsMarkups.DiscountMarkupValue
			|	END AS DiscountMarkupValue,");
		
		Query.Text = StrReplace(Query.Text, "&ExtendedVersion_2,", 
			"DiscountsMarkups.ExternalDataProcessorParameters         AS ExternalDataProcessorParameters,
			|	DiscountsMarkups.AdditionalFilterIsSet     AS AdditionalFilterIsSet,
			|	DiscountsMarkups.StorageOfDataCompositionSettings AS StorageOfDataCompositionSettings,
			|	DiscountsMarkups.ApplyVariants AS ApplyVariants,
			|	LoyaltyPrograms.BonusConversionCurrency      AS BonusConversionCurrency,
			|	LoyaltyPrograms.ConversionRateOfBonusesIntoCurrency AS ConversionRateOfBonusesIntoCurrency,");
		
		Query.Text = StrReplace(Query.Text, ",&ExtendedVersion_3", 
			"LEFT JOIN ExchangeRates AS CurrencyRatesProvision
			|		ON (CurrencyRatesProvision.Currency = DiscountsMarkups.DiscountMarkupCurrency)
			|	
			|		LEFT JOIN ExchangeRates AS DocumentExchangeRates
			|		ON (DocumentExchangeRates.Currency = &DocumentCurrency)
			|	
			|		LEFT JOIN Catalog.LoyaltyPrograms AS LoyaltyPrograms
			|		ON LoyaltyPrograms.Ref = DiscountsMarkups.LoyaltyProgram");
		
	Else
		
		Query.Text = StrReplace(Query.Text, "&ExtendedVersion_1,", 
			"DiscountsMarkups.DiscountMarkupValue,");
			
		Query.Text = StrReplace(Query.Text, "&ExtendedVersion_2,", "");
		
		Query.Text = StrReplace(Query.Text, ",&ExtendedVersion_3", "");
		
	EndIf;
	
	Return Query;
	
EndFunction

// The function generates a query for the table of current discounts (markups).
//
// Returns:
//	Query - Query
//
Function RequestTSTermsOfService(CalculationParameters)
	
	Query = New Query(
	"////#123456789#//////////////////////////////////////////////////////////
	|SELECT
	|	T.Ref AS DiscountMarkup,
	|	T.DiscountMarkupCondition AS DiscountMarkupCondition
	|FROM
	|	Catalog.DiscountsMarkups.DiscountMarkupConditions AS T
	|WHERE
	|	T.Ref IN(&DiscountsMarkups)
	|
	|UNION ALL
	|
	|SELECT
	|	T.Ref AS DiscountMarkup,
	|	T.Ref AS DiscountMarkupCondition
	|FROM
	|	Catalog.DiscountsMarkups AS T
	|WHERE
	|	T.Ref IN(&DiscountsMarkups)
	|	AND (T.ItemFilterOption <> VALUE(Enum.ItemFilterOptionsForDiscountMarkupCalculation.WithoutRestrictions)
	|	OR T.AdditionalFilterIsSet)
	|");
	
	Query.Parameters.Insert("DiscountsMarkups", CalculationParameters.DiscountsMarkups);
	
	Return Query;
	
EndFunction

// The function generates a query for the table of current discounts (markups).
//
// Returns:
//	Query - Query
//
Function RequestTermsOfService(CalculationParameters)
	
	Query = New Query(
	"SELECT DISTINCT
	|	T.Ref AS Ref,
	|	
	|	CASE
	|		WHEN (
	|				T.DiscountMarkupCondition = VALUE(Enum.DiscountMarkupTerms.ForOneTimeSalesVolume)
	|				OR T.DiscountMarkupCondition = VALUE(Enum.DiscountMarkupTerms.ForAccumulatedSalesVolume)
	|				)
	|				AND T.CriteriaOfApplicationLimitationForSalesVolume = VALUE(Enum.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.Sum)
	|			THEN T.RestrictionConditionValue * ISNULL(ExchangeRatesRestrictions.CourseNumerator, 1) * ISNULL(DocumentExchangeRates.CourseDenominator, 1) / (ISNULL(DocumentExchangeRates.CourseNumerator, 1) * ISNULL(ExchangeRatesRestrictions.CourseDenominator, 1))
	|		ELSE T.RestrictionConditionValue
	|	END AS RestrictionConditionValue
	|	
	|INTO DiscountMarkupConditions
	|FROM
	|	Catalog.DiscountsMarkups.DiscountMarkupConditions AS Conditions
	|	
	|		INNER JOIN Catalog.DiscountMarkupTerms AS T
	|		ON T.Ref = Conditions.DiscountMarkupCondition
	|		
	|		LEFT JOIN ExchangeRates AS ExchangeRatesRestrictions
	|		ON (ExchangeRatesRestrictions.Currency = Conditions.DiscountMarkupCondition.RestrictionCurrency)
	|		
	|		LEFT JOIN ExchangeRates AS DocumentExchangeRates
	|		ON (DocumentExchangeRates.Currency = &DocumentCurrency)
	|WHERE
	|	Conditions.Ref IN (&DiscountsMarkups)
	|;
	|
	|////#123456789#//////////////////////////////////////////////////////////
	|SELECT
	|	T.Ref                                         AS Ref,
	|	DiscountMarkupConditions.RestrictionConditionValue AS RestrictionConditionValue,
	|	T.DiscountMarkupCondition                          AS DiscountMarkupCondition,
	|	T.OptionOfCumulativeQuantityDiscountPeriodDetermination   AS OptionOfCumulativeQuantityDiscountPeriodDetermination,
	|	T.AccumulationOption                              AS AccumulationOption,
	|	T.RestrictionCurrency                              AS RestrictionCurrency,
	|	T.RestrictionCurrency.Code                          AS DigitalCurrencyCodeRestrictions,
	|	T.ComparisonTypeSSL                                   AS ComparisonTypeSSL,
	|	T.CriteriaOfApplicationLimitationForSalesVolume     AS CriteriaOfApplicationLimitationForSalesVolume,
	|	T.PaymentSchedule                                   AS PaymentSchedule,
	|	T.PaymentMethod                                    AS PaymentMethod,
	|	T.ProductSegmentRestrictions                 AS ProductSegmentRestrictions,
	|	T.AccumulationPeriod                               AS AccumulationPeriod,
	|	T.UsersGroup                            AS UsersGroup,
	|	T.LoyaltyCardKind                             AS LoyaltyCardKind,
	|	T.NumberOfAccumulationPeriods                   AS NumberOfAccumulationPeriods,
	|	T.ItemFilterOption                      AS ItemFilterOption,
	|	T.StorageOfDataCompositionSettings              AS StorageOfDataCompositionSettings,
	|	T.ExternalDataProcessorParameters                      AS ExternalDataProcessorParameters,
	|	T.NumberOfDaysBeforeBirthday                    AS NumberOfDaysBeforeBirthday,
	|	T.NumberOfDaysAfterBirthday                 AS NumberOfDaysAfterBirthday,
	|	T.IncludeCurrentSaleInAccumulatedSalesVolume  AS IncludeCurrentSaleInAccumulatedSalesVolume,
	|	T.ApplyVariants                        AS ApplyVariants,
	|	T.PartnersSegment                               AS PartnersSegment
	|FROM
	|	DiscountMarkupConditions AS DiscountMarkupConditions
	|		LEFT JOIN Catalog.DiscountMarkupTerms AS T
	|		ON T.Ref = DiscountMarkupConditions.Ref
	|");
	
	Query.Parameters.Insert("DiscountsMarkups",   CalculationParameters.DiscountsMarkups);
	Query.Parameters.Insert("DocumentCurrency", CalculationParameters.DocumentCurrency);
	
	Return Query;
	
EndFunction

// This function generates a query for the product table by segment.
//
// Returns:
//	Query - Query
//
Function QueryTemporaryTableProducts(CalculationParameters, MainTables)
	
	Query = New Query(
	"SELECT
	|	Goods.ConnectionKey          AS ConnectionKey,
	|	Goods.Products       AS Products,
	|	Goods.Characteristic     AS Characteristic,
	|	Goods.Package           AS Package,
	|	Goods.Series              AS Series,
	|	Goods.Warehouse              AS Warehouse,
	|
	|	CASE
	|		WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef) THEN
	|			9999999999
	|		ELSE
	|			CAST(DATEDIFF(&CurrentDate, Goods.ExpirationDate_, DAY) AS NUMBER(10))
	|	END AS NumberOfDaysBeforeExpirationPeriod,
	|
	|	Goods.PriceKind            AS PriceKind,
	|	Goods.Count         AS Count,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Price                             AS PricePerPackaging,
	|	Goods.NumberOfPackages * Goods.Price AS Sum
	|INTO TemporaryTableOfGoods_
	|FROM
	|	&ProductsWithExpirationDate AS Goods
	|	
	|INDEX BY
	|	Products,
	|	Characteristic
	|");
	
	ProductsWithExpirationDate = CalculationParameters.Goods.Copy(); // ValueTable
	ProductsWithExpirationDate.Columns.Add("ExpirationDate_", New TypeDescription("Date"));
	For Each RowOfGoods In ProductsWithExpirationDate Do
		If ValueIsFilled(RowOfGoods.Series) Then
			RowOfGoods.ExpirationDate_ = RowOfGoods.Series.ValidUntil_;
		EndIf;
	EndDo;
	
	Query.Parameters.Insert("ProductsWithExpirationDate", ProductsWithExpirationDate);
	Query.Parameters.Insert("CurrentDate",            CalculationParameters.CurrentDate);
	
	MainTables.Query.Parameters.Insert("ProductsWithExpirationDate", ProductsWithExpirationDate);
	
	Return Query;
	
EndFunction

// This function generates a query for the product table by segment.
//
// Returns:
//	Query - Query
//
Function QueryProductsBySegment(CalculationParameters)
	
	Query = New Query(
	"////#123456789#//////////////////////////////////////////////////////////
	|SELECT
	|	Goods.ConnectionKey             AS ConnectionKey,
	|	Goods.Products          AS Products,
	|	Goods.Characteristic        AS Characteristic,
	|	Goods.Package              AS Package,
	|	Goods.Count            AS Count,
	|	Goods.NumberOfPackages    AS NumberOfPackages,
	|	Goods.Series                 AS Series,
	|	Goods.PriceKind               AS PriceKind,
	|	SegmentProducts.Segment AS ProductSegment,
	|	T.PriceGroup              AS PriceGroup,
	|	Goods.Sum                 AS Sum
	|FROM
	|	TemporaryTableOfGoods_ AS Goods
	|	
	|		INNER JOIN InformationRegister.SegmentProducts AS SegmentProducts
	|		ON    Goods.Products   = SegmentProducts.Products
	|			AND Goods.Characteristic = SegmentProducts.Characteristic
	|
	|		LEFT JOIN Catalog.Products AS T
	|		ON T.Ref = Goods.Products
	|");
	
	Return Query;
	
EndFunction

// The function generates a query for a table of discount values (markups) by price groups.
//
// Returns:
//	Query - Query
//
Function RequestDiscountsMarginsByPriceGroups(CalculationParameters)
	
	Query = New Query(
	"////#123456789#//////////////////////////////////////////////////////////
	|SELECT
	|	SpecifyByPriceGroups.Ref        AS DiscountMarkup,
	|	SpecifyByPriceGroups.PriceGroup AS Key,
	|	CASE
	|		WHEN (DiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.Sum) OR DiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.DiscountMarkupAsAmountForEachRow))
	|			THEN SpecifyByPriceGroups.DiscountMarkupValue * ISNULL(CurrencyRatesProvision.CourseNumerator, 1) * ISNULL(DocumentExchangeRates.CourseDenominator, 1) / (ISNULL(DocumentExchangeRates.CourseNumerator, 1) * ISNULL(CurrencyRatesProvision.CourseDenominator, 1))
	|		ELSE SpecifyByPriceGroups.DiscountMarkupValue
	|	END AS Value
	|FROM
	|	Catalog.DiscountsMarkups AS DiscountsMarkups
	|		
	|		INNER JOIN Catalog.DiscountsMarkups.PriceGroups AS SpecifyByPriceGroups
	|		ON DiscountsMarkups.Ref = SpecifyByPriceGroups.Ref
	|		
	|		LEFT JOIN ExchangeRates AS CurrencyRatesProvision
	|		ON (CurrencyRatesProvision.Currency = DiscountsMarkups.DiscountMarkupCurrency)
	|		
	|		LEFT JOIN ExchangeRates AS DocumentExchangeRates
	|		ON (DocumentExchangeRates.Currency = &DocumentCurrency)
	|WHERE
	|	DiscountsMarkups.Ref IN (&DiscountsMarkups)
	|ORDER BY
	|	SpecifyByPriceGroups.Ref
	|");
	
	Query.Parameters.Insert("DiscountsMarkups", CalculationParameters.DiscountsMarkups);
	Query.Parameters.Insert("DocumentCurrency", CalculationParameters.DocumentCurrency);
	
	Return Query;
	
EndFunction

// This function generates a query for the item price table (the price is converted to the document currency per storage unit).
//
// Returns:
//	Query - Query
//
Function RequestProductPrice(CalculationParameters)

	If PriceManagementSystemServerCall.UsePriceManagementSystem25(CalculationParameters.CurrentDate) Then
		Query = New Query(
		"SELECT DISTINCT
		|	TemporaryTableOfGoods_.Products AS Products,
		|	TemporaryTableOfGoods_.Characteristic AS Characteristic,
		|	TemporaryTableOfGoods_.Package AS Package,
		|	CASE
		|		WHEN ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|		ELSE TemporaryTableOfGoods_.Characteristic.ItemsCharacteristicForPricing
		|	END AS PricingVariant,
		|	ISNULL(CASE
		|			WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|				THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
		|			ELSE TemporaryTableOfGoods_.Series.ItemsBatchForPricing
		|		END, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)) AS PricingBatch,
		|	CASE
		|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		ELSE TemporaryTableOfGoods_.Package
		|	END AS PricingPackage
		|INTO TemporaryTableOfGoods_25
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|		ON (ItemKinds.Ref = TemporaryTableOfGoods_.Products.ProductKind)
		|;
		|
		|////#123456789#//////////////////////////////////////////////////////////
		|SELECT
		|	ItemPricesCrossSectionOfTheLatest.PriceKind AS PriceKind,
		|	ItemPricesCrossSectionOfTheLatest.Products AS Products,
		|	TemporaryTableOfGoods_.Characteristic AS Characteristic,
		|	ItemPricesCrossSectionOfTheLatest.Package AS Package,
		|	ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor,
		|	CAST(ItemPricesCrossSectionOfTheLatest.Price 
		|		* ( ISNULL(ExchangeRates.CourseNumerator, 1) * ISNULL(DocumentExchangeRates.CourseDenominator, 1) )
		|		/ ( ISNULL(DocumentExchangeRates.CourseNumerator, 1) * ISNULL(ExchangeRates.CourseDenominator, 1) )
		|	AS NUMBER(31, 2)) AS Price
		|FROM
		|	InformationRegister.ItemsPrices25.SliceLast(
		|			ENDOFPERIOD(&CurrentDate, DAY),
		|			PriceKind IN
		|					(SELECT DISTINCT
		|						T.PriceKind
		|					FROM
		|						Catalog.DiscountsMarkups AS T
		|					WHERE
		|						T.Ref IN (&DiscountsMarkups)
		|						AND T.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.PriceKind))
		|				AND (Products, PricingVariant, PricingBatch, PricingPackage) IN
		|					(SELECT
		|						T.Products,
		|						T.PricingVariant,
		|						T.PricingBatch,
		|						T.PricingPackage
		|					FROM
		|						TemporaryTableOfGoods_25 AS T)) AS ItemPricesCrossSectionOfTheLatest
		|		LEFT JOIN TemporaryTableOfGoods_25 AS TemporaryTableOfGoods_
		|		ON ItemPricesCrossSectionOfTheLatest.Products = TemporaryTableOfGoods_.Products
		|			AND ItemPricesCrossSectionOfTheLatest.PricingVariant = TemporaryTableOfGoods_.PricingVariant
		|			AND ItemPricesCrossSectionOfTheLatest.PricingBatch = TemporaryTableOfGoods_.PricingBatch
		|			AND ItemPricesCrossSectionOfTheLatest.PricingPackage = TemporaryTableOfGoods_.PricingPackage
		|		LEFT JOIN ExchangeRates AS ExchangeRates
		|		ON (ExchangeRates.Currency = ItemPricesCrossSectionOfTheLatest.Currency)
		|		LEFT JOIN ExchangeRates AS DocumentExchangeRates
		|		ON (DocumentExchangeRates.Currency = &DocumentCurrency)");
	Else
		Query = New Query(
		"////#123456789#//////////////////////////////////////////////////////////
		|SELECT
		|	ItemPricesCrossSectionOfTheLatest.PriceKind        AS PriceKind,
		|	ItemPricesCrossSectionOfTheLatest.Products   AS Products,
		|	ItemPricesCrossSectionOfTheLatest.Characteristic AS Characteristic,
		|	ItemPricesCrossSectionOfTheLatest.Package       AS Package,
		|	
		|	ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor,
		|	
		|	CAST(ItemPricesCrossSectionOfTheLatest.Price 
		|		* ( ISNULL(ExchangeRates.CourseNumerator, 1) * ISNULL(DocumentExchangeRates.CourseDenominator, 1) )
		|		/ ( ISNULL(DocumentExchangeRates.CourseNumerator, 1) * ISNULL(ExchangeRates.CourseDenominator, 1) )
		|	AS NUMBER(31, 2)) AS Price
		|	
		|FROM
		|	InformationRegister.ItemsPrices.SliceLast(ENDOFPERIOD(&CurrentDate, DAY),
		|			PriceKind IN (SELECT DISTINCT
		|							T.PriceKind
		|						FROM
		|							Catalog.DiscountsMarkups AS T
		|						WHERE
		|							T.Ref IN (&DiscountsMarkups) AND T.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.PriceKind))
		|				AND (Products, Characteristic) IN (SELECT T.Products, T.Characteristic FROM TemporaryTableOfGoods_ AS T)
		|	
		|	) AS ItemPricesCrossSectionOfTheLatest
		|		
		|		LEFT JOIN ExchangeRates AS ExchangeRates
		|		ON (ExchangeRates.Currency = ItemPricesCrossSectionOfTheLatest.Currency)
		|		
		|		LEFT JOIN ExchangeRates AS DocumentExchangeRates
		|		ON (DocumentExchangeRates.Currency = &DocumentCurrency)");
	EndIf;	
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ItemPricesCrossSectionOfTheLatest.Package",
		"ItemPricesCrossSectionOfTheLatest.Products"));
	
	Query.Parameters.Insert("DiscountsMarkups",   CalculationParameters.DiscountsMarkups);
	Query.Parameters.Insert("DocumentCurrency", CalculationParameters.DocumentCurrency);
	Query.Parameters.Insert("CurrentDate",     CalculationParameters.CurrentDate);
	
	Return Query;
	
EndFunction
#EndRegion

#Region RequestsForVerificationOfDiscountTerms

// Parameters:
// 	DataSource - ValueTableRow - contains including:
// 		* Ref - CatalogRef.DiscountMarkupTerms - Link to a reference list item
// 	ReplacementString - String
// 
// Returns:
// 	Structure:
// 		* QueryText - String
// 		* Parameters - Structure
// 
Function FilterDataByProductType(DataSource, ReplacementString) Export
	
	If TypeOf(DataSource.Ref) = Type("CatalogRef.DiscountMarkupTerms") Then
		If DataSource.CriteriaOfApplicationLimitationForSalesVolume = Enums.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.NumberOfSimilarOnes Then
			DataCompositionSchema = Catalogs.DiscountsMarkups.GetTemplate("FilterTermsQuantityOfSimilar");
		ElsIf DataSource.CriteriaOfApplicationLimitationForSalesVolume = Enums.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.DifferentItemsCount Then
			DataCompositionSchema = Catalogs.DiscountsMarkups.GetTemplate("FilterTermsQuantityOfDifferent");
		Else
			DataCompositionSchema = Catalogs.DiscountsMarkups.GetTemplate("FilterTermsAmountQuantity");
		EndIf;
	Else
		DataCompositionSchema = Catalogs.DiscountsMarkups.GetTemplate("RowFilter");
		
		Set = DataCompositionSchema.DataSets.Find("DataSet");
		ProvisionInDocumentsServer.DiscountsSurchargesReplaceBalanceInWarehouseRedefinable(Set.Query);
		Fields = "FilterByProductCategory.Products,FilterByProductCategory.Characteristic,FilterByProductCategory.Warehouse";
		Set.Query = InformationRegisters.ProductRestrictions.SubstituteConnection(Set.Query, "SubstituteGoodsRestriction", Fields);
		
	EndIf;
	
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	Composer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	If TypeOf(DataSource.Ref) = Type("CatalogRef.DiscountMarkupTerms") Then
		AdditionalFilterIsSet = False;
	Else
		AdditionalFilterIsSet = DataSource.AdditionalFilterIsSet;
	EndIf;
	
	If DataSource.ItemFilterOption = Enums.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter
		Or AdditionalFilterIsSet Then
		StorageOfDataCompositionSettings = DataSource.StorageOfDataCompositionSettings; // ValueStorage
		Settings = StorageOfDataCompositionSettings.Get();
	EndIf;
	
	If DataSource.ItemFilterOption = Enums.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter Then
		
		If Settings <> Undefined And TMCommonUseClientServer.HasObjectAttribute(Settings, "FilterRemainingGoodsByShelfLives") Then
			DataCompositionClientServer.CopyElements(Composer.Settings.Filter, Settings.FilterRemainingGoodsByShelfLives.Filter, False);
		EndIf;
		
		SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(Composer);
		
	ElsIf DataSource.ItemFilterOption = Enums.ItemFilterOptionsForDiscountMarkupCalculation.ProductSegment Then
		
		FilterElement = Composer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = New DataCompositionField("ProductSegment");
		FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = DataSource.ProductSegmentRestrictions;
		FilterElement.Use = True;
		
		SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(Composer);
		
	ElsIf DataSource.ItemFilterOption = Enums.ItemFilterOptionsForDiscountMarkupCalculation.NotProductSegment Then
		
		FilterElement = Composer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = New DataCompositionField("NotProductSegment");
		FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = DataSource.ProductSegmentRestrictions;
		FilterElement.Use = True;
		
		SegmentsServer.EnableSelectionByNonSegmentOfVSPDProductItem(Composer);
		
	ElsIf DataSource.ItemFilterOption = Enums.ItemFilterOptionsForDiscountMarkupCalculation.ItemList Then
		
		DataCompositionClientServer.SetParameter(Composer, "FilterByListedGoodsIsUsed", True, True);
		DataCompositionClientServer.SetParameter(Composer, "Source", DataSource.Ref, True);
		
	EndIf;
	
	If AdditionalFilterIsSet Then
		If Settings <> Undefined And TMCommonUseClientServer.HasObjectAttribute(Settings, "AdditionalConditions") Then
			DataCompositionClientServer.CopyElements(Composer.Settings.Filter, Settings.AdditionalConditions.Filter, False);
		EndIf;
	EndIf;
	
	If TypeOf(DataSource.Ref) = Type("CatalogRef.DiscountMarkupTerms") Then
		If DataSource.CriteriaOfApplicationLimitationForSalesVolume = Enums.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.NumberOfSimilarOnes Then
			DataCompositionClientServer.SetParameter(Composer, "ApplyVariants", DataSource.ApplyVariants, True);
		ElsIf DataSource.CriteriaOfApplicationLimitationForSalesVolume = Enums.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.DifferentItemsCount Then
			DataCompositionClientServer.SetParameter(Composer, "ApplyVariants", DataSource.ApplyVariants, True);
		EndIf;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema,
			Composer.GetSettings(),,,
			Type("DataCompositionValueCollectionTemplateGenerator"));
	QueryText = DataCompositionTemplate.DataSets.DataSet.Query;
	
	SeparatorComment = "////////////////////////////////////////////////////////////////////////////////";
	Position = StrFind(QueryText, SeparatorComment);
	QueryText = Mid(QueryText, Position + StrLen(SeparatorComment) + 1);
	QueryText = StrReplace(QueryText, "TemplateTable_", ReplacementString);
	
	Texts = StrSplit(QueryText, ";");
	Texts[Texts.Count() - 1] = StrReplace(Texts[Texts.Count() - 1], Chars.LF + "FROM", Chars.LF + "INTO FilterByProductCategory" + Chars.LF + "FROM");
	
	ReturnValue = New Structure;
	ReturnValue.Insert("QueryText", StrConcat(Texts, ";") + Chars.LF);
	ReturnValue.Insert("Parameters", New Structure);
	For Each ParameterValue In DataCompositionTemplate.ParameterValues Do
		ReturnValue.Parameters.Insert(ParameterValue.Name, ParameterValue.Value);
	EndDo;
	
	Return ReturnValue;
	
EndFunction

Function PrepareFilterByProductCategory(Query, DataSource, ReplacementString, CalculationParameters)
	
	FilterDataByProductType = FilterDataByProductType(DataSource, ReplacementString);
	
	Postfixes = RequestPackagePostfixes();
	For Each KeyValue In FilterDataByProductType.Parameters Do
		ParameterName = KeyValue.Key;
		If Not CalculationParameters.Property(ParameterName) Then
			NewParameterName = ParameterName + "Cached_1";
			ReplaceParameterNameInRequest(FilterDataByProductType.QueryText, ParameterName, NewParameterName, Postfixes);
		Else
			NewParameterName = ParameterName;
		EndIf;
		Query.SetParameter(NewParameterName, KeyValue.Value);
	EndDo;
	
	Return FilterDataByProductType.QueryText;
	
EndFunction

// The function generates a query for a table of calculated discounts for a one-time sale with a condition for a row.
//
// Returns:
//	Query - Query
//
Function RequestToDefineProductItemsForWhichDiscountIsGranted(DiscountMarkup, CalculationParameters, ParametersToFillIn)
	
	Query = New Query;
	
	TempTableName = "TemporaryTableOfGoods_";
	
	QueryText = PrepareFilterByProductCategory(Query, DiscountMarkup, TempTableName, CalculationParameters);
	QueryText = QueryText + Common.QueryBatchSeparator();
	
	QueryText = QueryText +
	"//// #123456789#
	|SELECT
	|	Goods.ConnectionKey AS ConnectionKey,
	|	UNDEFINED     AS IndicatorValue,
	|	-1               AS MultiplicityOfExecution
	|FROM
	|	FilterByProductCategory AS Goods
	|";
	
	Query.Text = QueryText;
	
	FillInParametersForDeterminingProductItemItemsForWhichDiscountIsGranted(Query, CalculationParameters, ParametersToFillIn);
	
	Return Query;
	
EndFunction

// The function generates a query for a table of calculated discounts for a one-time sale with a condition for the document.
//
// Returns:
//	Query - Query
//
Function RequestConditionForOneTimeSaleWithConditionForDocument(DiscountMarkupCondition, CalculationParameters, ParametersToFillIn)
	
	Query = New Query;
	
	TempTableName = "TemporaryTableOfGoods_";
	
	QueryText = PrepareFilterByProductCategory(Query, DiscountMarkupCondition, TempTableName, CalculationParameters);
	QueryText = QueryText + Common.QueryBatchSeparator();
	
	QueryText = QueryText +
	"//// #123456789#
	|SELECT
	|	&TextIndicatorValue AS IndicatorValue,
	|	&MultiplicityText          AS MultiplicityOfExecution
	|FROM
	|	FilterByProductCategory AS Goods
	|";
	
	PrepareQueryTextForCheckingConditionAndCalculatingMultiplicity(QueryText, DiscountMarkupCondition);
	
	Query.Text = QueryText;
	
	FillInParametersRequestConditionsForOneTimeSaleWithConditionForDocument(
		Query,
		DiscountMarkupCondition,
		CalculationParameters, ParametersToFillIn);
	
	Return Query;
	
EndFunction

// The function generates a query to get a temporary table of the accumulated sales volume for the partner.
//
// Returns:
//	Query - Query
//
Function QueryAccumulatedSalesVolumeForPartnerForPeriod(DiscountMarkupCondition, Interval, CalculationParameters)
	
	Query = New Query;
	
	QueryText = 
	"SELECT
	|	RevenueAndCostOfSalesTurnover.ItemsLocationAttributes.Products    AS Products,
	|	RevenueAndCostOfSalesTurnover.ItemsLocationAttributes.Characteristic  AS Characteristic,
	|	ISNULL(RevenueAndCostOfSalesTurnover.SetAccountingDimension.ProductsInSet,
	|		VALUE(Catalog.Products.EmptyRef))                           AS ProductsInSet,
	|	ISNULL(RevenueAndCostOfSalesTurnover.SetAccountingDimension.ItemVariantOfSet,
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef))             AS ItemVariantOfSet,
	|	RevenueAndCostOfSalesTurnover.CountTurnover                           AS Count,
	|	RevenueAndCostOfSalesTurnover.RevenueAmountTurnover
	|	* ISNULL(ExchangeRatesSource.CourseNumerator, 1) * ISNULL(ExchangeRatesTermsOfProvision.CourseDenominator, 1)
	|	 / (ISNULL(ExchangeRatesTermsOfProvision.CourseNumerator, 1) * ISNULL(ExchangeRatesSource.CourseDenominator, 1)) AS Sum
	|	
	|INTO RawData
	|	
	|FROM
	|	AccumulationRegister.RevenueAndCOGS.Turnovers(
	|			&StartDate,
	|			&EndDate,
	|			Auto,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|				WHERE
	|					AccountingDimensionByPartners.Partner = &Partner AND AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer))
	|	) AS RevenueAndCostOfSalesTurnover
	|	
	|		LEFT JOIN ExchangeRates AS ExchangeRatesSource
	|		ON (ExchangeRatesSource.Currency = &ManagementAccountingCurrency)
	|	
	|		LEFT JOIN ExchangeRates AS ExchangeRatesTermsOfProvision
	|		ON (ExchangeRatesTermsOfProvision.Currency = &CurrencyConditions)
	|	
	|UNION ALL
	|	
	|SELECT
	|	RevenueAndCOGS.ItemsLocationAttributes.Products    AS Products,
	|	RevenueAndCOGS.ItemsLocationAttributes.Characteristic  AS Characteristic,
	|	ISNULL(RevenueAndCOGS.SetAccountingDimension.ProductsInSet,
	|		VALUE(Catalog.Products.EmptyRef))                    AS ProductsInSet,
	|	ISNULL(RevenueAndCOGS.SetAccountingDimension.ItemVariantOfSet,
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef))      AS ItemVariantOfSet,
	|	-RevenueAndCOGS.Count                                AS Count,
	|	-RevenueAndCOGS.RevenueAmount
	|	* ISNULL(ExchangeRatesSource.CourseNumerator, 1) * ISNULL(ExchangeRatesTermsOfProvision.CourseDenominator, 1)
	|	 / (ISNULL(ExchangeRatesTermsOfProvision.CourseNumerator, 1) * ISNULL(ExchangeRatesSource.CourseDenominator, 1)) AS Sum
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|		LEFT JOIN ExchangeRates AS ExchangeRatesSource
	|		ON (ExchangeRatesSource.Currency = &ManagementAccountingCurrency)
	|	
	|		LEFT JOIN ExchangeRates AS ExchangeRatesTermsOfProvision
	|		ON (ExchangeRatesTermsOfProvision.Currency = &CurrencyConditions)
	|	
	|WHERE
	|	RevenueAndCOGS.Recorder = &Recorder
	|	AND RevenueAndCOGS.Period BETWEEN &StartDateCashRegisterReceipt AND &EndDateOfCashRegisterReceipt
	|
	|UNION ALL
	|	
	|SELECT
	|	ProductsSold.Products   AS Products,
	|	ProductsSold.Characteristic AS Characteristic,
	|	ProductsSold.ProductsInSet   AS ProductsInSet,
	|	ProductsSold.ItemVariantOfSet AS ItemVariantOfSet,
	|	ProductsSold.Count     AS Count,
	|	ProductsSold.Sum
	|	* ISNULL(ExchangeRatesSource.CourseNumerator, 1) * ISNULL(ExchangeRatesTermsOfProvision.CourseDenominator, 1)
	|	 / (ISNULL(ExchangeRatesTermsOfProvision.CourseNumerator, 1) * ISNULL(ExchangeRatesSource.CourseDenominator, 1)) AS Sum
	|FROM
	|	Document.CashRegisterReceipt.Goods AS ProductsSold
	|	
	|		LEFT JOIN ExchangeRates AS ExchangeRatesSource
	|		ON (ExchangeRatesSource.Currency = ProductsSold.Ref.Currency)
	|	
	|		LEFT JOIN ExchangeRates AS ExchangeRatesTermsOfProvision
	|		ON (ExchangeRatesTermsOfProvision.Currency = &CurrencyConditions)
	|	
	|WHERE
	|	ProductsSold.Ref IN (
	|		SELECT
	|			T.Ref
	|		FROM
	|			Document.CashRegisterReceipt AS T
	|		WHERE
	|			T.Date BETWEEN &StartDateCashRegisterReceipt AND &EndDateOfCashRegisterReceipt
	|			AND T.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|			AND T.CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	|			AND T.Partner = &Partner
	|			AND T.Partner <> VALUE(Catalog.Partners.RetailCustomer)
	|)
	|	
	|UNION ALL
	|	
	|SELECT
	|	ProductsSold.Products   AS Products,
	|	ProductsSold.Characteristic AS Characteristic,
	|	ProductsSold.ProductsInSet   AS ProductsInSet,
	|	ProductsSold.ItemVariantOfSet AS ItemVariantOfSet,
	|	-ProductsSold.Count     AS Count,
	|	-ProductsSold.Sum
	|	* ISNULL(ExchangeRatesSource.CourseNumerator, 1) * ISNULL(ExchangeRatesTermsOfProvision.CourseDenominator, 1)
	|	 / (ISNULL(ExchangeRatesTermsOfProvision.CourseNumerator, 1) * ISNULL(ExchangeRatesSource.CourseDenominator, 1)) AS Sum
	|FROM
	|	Document.CashRegisterReceiptReturn.Goods AS ProductsSold
	|	
	|		LEFT JOIN ExchangeRates AS ExchangeRatesSource
	|		ON (ExchangeRatesSource.Currency = ProductsSold.Ref.Currency)
	|	
	|		LEFT JOIN ExchangeRates AS ExchangeRatesTermsOfProvision
	|		ON (ExchangeRatesTermsOfProvision.Currency = &CurrencyConditions)
	|	
	|WHERE
	|	ProductsSold.Ref IN (
	|		SELECT
	|			T.Ref
	|		FROM
	|			Document.CashRegisterReceiptReturn AS T
	|		WHERE
	|			T.Date BETWEEN &StartDateCashRegisterReceipt AND &EndDateOfCashRegisterReceipt
	|			AND T.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|			AND T.CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	|			AND T.Partner = &Partner
	|			AND T.Partner <> VALUE(Catalog.Partners.RetailCustomer)
	|	AND ProductsSold.NumberOfPackages <> 0
	|)";
	
	If DiscountMarkupCondition.IncludeCurrentSaleInAccumulatedSalesVolume Then
		QueryText = QueryText + Chars.LF +
		"UNION ALL
		|";
		
		QueryText = QueryText +
		"SELECT
		|	ProductsSold.Products   AS Products,
		|	ProductsSold.Characteristic AS Characteristic,
		|	VALUE(Catalog.Products.EmptyRef)               AS ProductsInSet,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
		|	ProductsSold.Count AS Count,
		|	ProductsSold.Sum
		|	* ISNULL(ExchangeRatesSource.CourseNumerator, 1) * ISNULL(ExchangeRatesTermsOfProvision.CourseDenominator, 1)
		|	 / (ISNULL(ExchangeRatesTermsOfProvision.CourseNumerator, 1) * ISNULL(ExchangeRatesSource.CourseDenominator, 1)) AS Sum
		|FROM
		|	TemporaryTableOfGoods_ AS ProductsSold
		|	
		|		LEFT JOIN ExchangeRates AS ExchangeRatesSource
		|		ON (ExchangeRatesSource.Currency = &DocumentCurrency)
		|	
		|		LEFT JOIN ExchangeRates AS ExchangeRatesTermsOfProvision
		|		ON (ExchangeRatesTermsOfProvision.Currency = &CurrencyConditions)
		|";
	EndIf;
	
	Query.Text = QueryText;
	
	FillInQueryParametersAccumulatedSalesByPartnerForPeriod(
		Query,
		DiscountMarkupCondition,
		Interval,
		CalculationParameters);
	
	TempTableName = TemporaryTableNameAccumulatedSales(DiscountMarkupCondition, Interval);
	
	Query.Text = StrReplace(Query.Text, "INTO RawData", "INTO" + " " + TempTableName);
	
	Return Query;
	
EndFunction

// The function generates a query to get a temporary table of the accumulated sales volume for the agreement.
//
// Returns:
//	Query - Query
//
Function QueryAccumulatedSalesUnderTradeAgreementForPeriod(DiscountMarkupCondition, Interval, CalculationParameters)
	
	Query = New Query;
	
	QueryText = 
	"SELECT
	|	RevenueAndCostOfSalesTurnover.ItemsLocationAttributes.Products    AS Products,
	|	RevenueAndCostOfSalesTurnover.ItemsLocationAttributes.Characteristic  AS Characteristic,
	|	ISNULL(RevenueAndCostOfSalesTurnover.SetAccountingDimension.ProductsInSet,
	|		VALUE(Catalog.Products.EmptyRef))                           AS ProductsInSet,
	|	ISNULL(RevenueAndCostOfSalesTurnover.SetAccountingDimension.ItemVariantOfSet,
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef))             AS ItemVariantOfSet,
	|	RevenueAndCostOfSalesTurnover.CountTurnover                           AS Count,
	|	RevenueAndCostOfSalesTurnover.RevenueAmountTurnover
	|	* ISNULL(ExchangeRatesSource.CourseNumerator, 1) * ISNULL(ExchangeRatesTermsOfProvision.CourseDenominator, 1)
	|	 / (ISNULL(ExchangeRatesTermsOfProvision.CourseNumerator, 1) * ISNULL(ExchangeRatesSource.CourseDenominator, 1)) AS Sum
	|	
	|INTO RawData
	|	
	|FROM
	|	AccumulationRegister.RevenueAndCOGS.Turnovers(
	|			&StartDate,
	|			&EndDate,
	|			Auto,
	|			Terms = &Terms
	|			AND AccountingDimensionByPartners IN
	|				(SELECT
	|					AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|				WHERE
	|					AccountingDimensionByPartners.Partner = &Partner AND AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer))
	|	) AS RevenueAndCostOfSalesTurnover
	|	
	|		LEFT JOIN ExchangeRates AS ExchangeRatesSource
	|		ON (ExchangeRatesSource.Currency = &ManagementAccountingCurrency)
	|	
	|		LEFT JOIN ExchangeRates AS ExchangeRatesTermsOfProvision
	|		ON (ExchangeRatesTermsOfProvision.Currency = &CurrencyConditions)
	|	
	|UNION ALL
	|	
	|SELECT
	|	RevenueAndCOGS.ItemsLocationAttributes.Products    AS Products,
	|	RevenueAndCOGS.ItemsLocationAttributes.Characteristic  AS Characteristic,
	|	ISNULL(RevenueAndCOGS.SetAccountingDimension.ProductsInSet,
	|		VALUE(Catalog.Products.EmptyRef))                    AS ProductsInSet,
	|	ISNULL(RevenueAndCOGS.SetAccountingDimension.ItemVariantOfSet,
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef))      AS ItemVariantOfSet,
	|	-RevenueAndCOGS.Count                                AS Count,
	|	-RevenueAndCOGS.RevenueAmount
	|	* ISNULL(ExchangeRatesSource.CourseNumerator, 1) * ISNULL(ExchangeRatesTermsOfProvision.CourseDenominator, 1)
	|	 / (ISNULL(ExchangeRatesTermsOfProvision.CourseNumerator, 1) * ISNULL(ExchangeRatesSource.CourseDenominator, 1)) AS Sum
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|		LEFT JOIN ExchangeRates AS ExchangeRatesSource
	|		ON (ExchangeRatesSource.Currency = &ManagementAccountingCurrency)
	|	
	|		LEFT JOIN ExchangeRates AS ExchangeRatesTermsOfProvision
	|		ON (ExchangeRatesTermsOfProvision.Currency = &CurrencyConditions)
	|	
	|WHERE
	|	RevenueAndCOGS.Recorder = &Recorder
	|	AND RevenueAndCOGS.Period BETWEEN &PSStartDate AND &PSEndDate
	|";
	
	If DiscountMarkupCondition.IncludeCurrentSaleInAccumulatedSalesVolume Then
		QueryText = QueryText + Chars.LF +
		"UNION ALL
		|";
		
		QueryText = QueryText +
		"SELECT
		|	ProductsSold.Products   AS Products,
		|	ProductsSold.Characteristic AS Characteristic,
		|	VALUE(Catalog.Products.EmptyRef)               AS ProductsInSet,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
		|	ProductsSold.Count AS Count,
		|	ProductsSold.Sum
		|	* ISNULL(ExchangeRatesSource.CourseNumerator, 1) * ISNULL(ExchangeRatesTermsOfProvision.CourseDenominator, 1)
		|	 / (ISNULL(ExchangeRatesTermsOfProvision.CourseNumerator, 1) * ISNULL(ExchangeRatesSource.CourseDenominator, 1)) AS Sum
		|FROM
		|	TemporaryTableOfGoods_ AS ProductsSold
		|	
		|		LEFT JOIN ExchangeRates AS ExchangeRatesSource
		|		ON (ExchangeRatesSource.Currency = &DocumentCurrency)
		|	
		|		LEFT JOIN ExchangeRates AS ExchangeRatesTermsOfProvision
		|		ON (ExchangeRatesTermsOfProvision.Currency = &CurrencyConditions)
		|";
	EndIf;
	
	Query.Text = QueryText;
	
	FillInQueryParametersAccumulatedSalesVolumeUnderTradeAgreementForPeriod(
		Query,
		DiscountMarkupCondition,
		Interval,
		CalculationParameters);
	
	TempTableName = TemporaryTableNameAccumulatedSales(DiscountMarkupCondition, Interval);
	
	Query.Text = StrReplace(Query.Text, "INTO RawData", "INTO" + " " + TempTableName);
	
	Return Query;
	
EndFunction

// The function generates a query for the table of calculated discounts for the accumulated sales volume for the partner.
//
// Returns:
//	Query - Query
//
Function RequestConditionsForAccumulatedSalesVolumeForPartnerForPeriod(DiscountMarkupCondition, Interval, CalculationParameters, ParametersToFillIn)
	
	Query = New Query;
	
	If ParametersToFillIn = "Cached_" Then
		TempTableName = "RawData";
	Else
		TempTableName = TemporaryTableNameAccumulatedSales(DiscountMarkupCondition, Interval);
	EndIf;
	
	QueryText = PrepareFilterByProductCategory(Query, DiscountMarkupCondition, TempTableName, CalculationParameters);
	QueryText = QueryText + Common.QueryBatchSeparator();
	
	QueryText = QueryText +
	"//// #123456789#
	|SELECT
	|	&TextIndicatorValue AS IndicatorValue,
	|	&MultiplicityText          AS MultiplicityOfExecution
	|FROM
	|	FilterByProductCategory AS Goods
	|";
	
	PrepareQueryTextForCheckingConditionAndCalculatingMultiplicity(QueryText, DiscountMarkupCondition);
	
	Query.Text = QueryText;
	
	FillInParametersQueryConditionsForAccumulatedSalesByPartnerForPeriod(
		Query,
		DiscountMarkupCondition,
		Interval,
		CalculationParameters, ParametersToFillIn);
	
	Return Query;
	
EndFunction

// The function generates a query for the table of calculated discounts for the accumulated sales volume under the trade agreement.
//
// Returns:
//	Query - Query
//
Function RequestTermsAndConditionsForAccumulatedSalesUnderTradeAgreementForPeriod(DiscountMarkupCondition, Interval, CalculationParameters, ParametersToFillIn)
	
	Query = New Query;
	
	If ParametersToFillIn = "Cached_" Then
		TempTableName = "RawData";
	Else
		TempTableName = TemporaryTableNameAccumulatedSales(DiscountMarkupCondition, Interval);
	EndIf;
	
	QueryText = PrepareFilterByProductCategory(Query, DiscountMarkupCondition, TempTableName, CalculationParameters);
	QueryText = QueryText + Common.QueryBatchSeparator();
	
	QueryText = QueryText +
	"//// #123456789#
	|SELECT
	|	&TextIndicatorValue AS IndicatorValue,
	|	&MultiplicityText          AS MultiplicityOfExecution
	|FROM
	|	FilterByProductCategory AS Goods
	|";
	
	PrepareQueryTextForCheckingConditionAndCalculatingMultiplicity(QueryText, DiscountMarkupCondition);
	
	Query.Text = QueryText;
	
	FillInParametersQueryConditionsForAccumulatedSalesUnderTradeAgreementForPeriod(
		Query,
		DiscountMarkupCondition,
		Interval,
		CalculationParameters, ParametersToFillIn);
	
	Return Query;
	
EndFunction

// The function generates a query for the table of calculated discounts for compliance with the payment schedule.
//
// Returns:
//	Query - Query
//
Function CheckConditionForPaymentSchedule(DiscountMarkupCondition, Context)
	
	MultiplicityOfExecution = 0;
	
	If (Context.PaymentSchedule = DiscountMarkupCondition.PaymentSchedule) Then
		MultiplicityOfExecution = -1;
	EndIf;
	
	Return MultiplicityOfExecution;
	
EndFunction

// The function generates a query for the table of calculated discounts for the payment form.
//
// Returns:
//	Query - Query
//
Function CheckConditionForPaymentForm(DiscountMarkupCondition, Context)
	
	MultiplicityOfExecution = 0;
	
	If (Context.PaymentMethod = DiscountMarkupCondition.PaymentMethod) Then
		MultiplicityOfExecution = -1;
	EndIf;
	
	Return MultiplicityOfExecution;
	
EndFunction

// The function generates a request to verify that the loyalty card is not registered.
//
// Returns:
//	Query - Query
//
Function RequestConditionsLoyaltyCardNotRegistered(DiscountMarkupCondition, CalculationParameters)

	Query = New Query(
	"////#123456789#//////////////////////////////////////////////////////////
	|SELECT
	|	-1 AS MultiplicityOfExecution
	|WHERE
	|	NOT &TypeOfLoyaltyCardConditions IN
	|		(SELECT DISTINCT
	|			T.Owner
	|		FROM
	|			Catalog.LoyaltyCards AS T
	|		WHERE
	|			T.Partner = &Partner
	|			AND T.Partner <> VALUE(Catalog.Partners.EmptyRef))");
	
	Query.SetParameter("TypeOfLoyaltyCardConditions", DiscountMarkupCondition.LoyaltyCardKind);
	Query.SetParameter("Partner", CalculationParameters.Partner);
	
	Return Query;
	
EndFunction

// This function generates a request to verify that the partner is the owner of the loyalty card.
//
// Returns:
//	Query - Query
//
Function RequestConditionsForLoyaltyCard(DiscountMarkupCondition, CalculationParameters)

	Query = New Query(
	"////#123456789#//////////////////////////////////////////////////////////
	|SELECT
	|	-1 AS MultiplicityOfExecution
	|WHERE
	|	&TypeOfLoyaltyCardConditions IN
	|		(SELECT DISTINCT
	|			T.Owner
	|		FROM
	|			Catalog.LoyaltyCards AS T
	|		WHERE
	|			T.Partner = &Partner
	|			AND T.Partner <> VALUE(Catalog.Partners.EmptyRef)
	|			AND T.Status = VALUE(Enum.LoyaltyCardStatuses.Valid))");
	
	Query.SetParameter("TypeOfLoyaltyCardConditions", DiscountMarkupCondition.LoyaltyCardKind);
	Query.SetParameter("Partner", CalculationParameters.Partner);
	
	Return Query;
	
EndFunction

// The function generates a query for the table of calculated discounts with a restriction on the user group.
//
// Returns:
//	Query - Query
//
Function RequestRestrictionByUserGroupCondition(DiscountMarkupCondition, CalculationParameters)

	Query = New Query(
	"////#123456789#//////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	-1 AS MultiplicityOfExecution
	|FROM
	|	Catalog.UserGroups.Content AS UserGroupsComposition
	|WHERE
	|	UserGroupsComposition.Ref = &UserGroupConditions
	|	AND UserGroupsComposition.User = &User");
	
	Query.SetParameter("UserGroupConditions", DiscountMarkupCondition.UsersGroup);
	Query.SetParameter("User", CalculationParameters.User);
	
	Return Query;
	
EndFunction

// The function generates a query for the table of calculated discounts during the sale.
//
// Parameters:
// 	DiscountMarkupCondition - ValueTableRow - contains including:
// 		* Ref - CatalogRef.DiscountMarkupTerms - Link to a reference list item
//
// Returns:
//	Query - Query
//
Function RequestTermsForTimeOfSale(DiscountMarkupCondition, CalculationParameters)

	Query = New Query(
	"////#123456789#//////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	-1 AS MultiplicityOfExecution
	|FROM
	|	Catalog.DiscountMarkupTerms.TimeOfValidity AS TimeOfValidity
	|WHERE
	|	TimeOfValidity.Ref = &Condition
	|	AND TimeOfValidity.WeekDay = &WeekDay
	|	AND (TimeOfValidity.BeginTime <= &CurrentTime AND TimeOfValidity.EndTime >= &CurrentTime)");
	
	Query.SetParameter("Condition", DiscountMarkupCondition.Ref);
	Query.SetParameter("CurrentTime", CalculationParameters.CurrentTime);
	Query.SetParameter("WeekDay", CalculationParameters.WeekDay);
	
	Return Query;
	
EndFunction

// This function generates a query for the table of calculated discounts for entering a partner in a segment.
//
// Returns:
//	Query - Query
//
Function RequestForPartnerSSegmentEntryCondition(DiscountMarkupCondition, CalculationParameters)

	Query = New Query(
	"////#123456789#//////////////////////////////////////////////////////////
	|SELECT
	|	-1 AS MultiplicityOfExecution
	|WHERE
	|	&PartnerSegmentConditions IN
	|			(SELECT DISTINCT
	|				T.Segment AS Segment
	|			FROM
	|				InformationRegister.SegmentPartners AS T
	|			WHERE
	|				T.Partner = &Partner)");
	
	Query.SetParameter("PartnerSegmentConditions", DiscountMarkupCondition.PartnersSegment);
	Query.SetParameter("Partner", CalculationParameters.Partner);
	
	Return Query;
	
EndFunction

// This function generates a request to verify that the partner is the owner of the loyalty card.
//
// Returns:
//	Query - Query
//
Function RequestConditionsForBirthday(DiscountMarkupCondition, CalculationParameters)

	Query = New Query(
	"////#123456789#//////////////////////////////////////////////////////////
	|SELECT
	|	-1 AS MultiplicityOfExecution
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	Partners.Ref = &Partner
	|	AND Partners.BirthDate <> DATETIME(1, 1, 1)
	|	AND DATEADD(DATEADD(Partners.BirthDate, DAY, &ShiftDays), YEAR, YEAR(&StartDate) - YEAR(Partners.BirthDate)) BETWEEN &StartDate AND &EndDate
	|");
	
	EndDate 	= EndOfDay(CalculationParameters.CurrentDate) + DiscountMarkupCondition.NumberOfDaysAfterBirthday * 24*60*60;
	StartDate 		= BegOfDay(CalculationParameters.CurrentDate) - DiscountMarkupCondition.NumberOfDaysBeforeBirthday * 24*60*60;
	If Year(StartDate) = Year(EndDate) Then
		ShiftDays 		= 0;
	Else
		ShiftDays 		= DayOfYear(EndOfYear(StartDate)) - DayOfYear(StartDate)+1;
		EndDate 	= EndDate + ShiftDays * 24*60*60;
		StartDate 		= StartDate + ShiftDays * 24*60*60;
	EndIf;		
	
	Query.SetParameter("EndDate", 	EndDate);
	Query.SetParameter("StartDate", 	StartDate);
	Query.SetParameter("ShiftDays", 		ShiftDays);
	Query.SetParameter("Partner", 		CalculationParameters.Partner);
	
	Return Query;
	
EndFunction


Procedure FillInQueryParametersAccumulatedSalesByPartnerForPeriod(Query, DiscountMarkupCondition, Interval, CalculationParameters)
	
	Query.SetParameter("CurrencyConditions",              DiscountMarkupCondition.RestrictionCurrency);
	
	Query.SetParameter("Partner",                    CalculationParameters.Partner);
	Query.SetParameter("ManagementAccountingCurrency", CalculationParameters.ManagementAccountingCurrency);
	Query.SetParameter("DocumentCurrency",            CalculationParameters.DocumentCurrency);
	Query.SetParameter("CurrentDate",                CalculationParameters.CurrentDate);
	Query.SetParameter("Recorder",                CalculationParameters.Recorder);
	
	If Interval.StartDate <> Undefined Then
		Query.SetParameter("StartDateCashRegisterReceipt", Interval.StartDate);
		Query.SetParameter("StartDate",       Interval.StartDate);
	Else
		Query.SetParameter("StartDateCashRegisterReceipt", Date(1,1,1));
		Query.SetParameter("StartDate", "");
	EndIf;
	
	If Interval.EndDate <> Undefined Then
		Query.SetParameter("EndDateOfCashRegisterReceipt", Interval.EndDate);
		Query.SetParameter("EndDate",       Interval.EndDate);
	Else
		Query.SetParameter("EndDateOfCashRegisterReceipt", EndOfDay(CurrentSessionDate()));
		Query.SetParameter("EndDate", "");
	EndIf;

EndProcedure

Procedure FillInQueryParametersAccumulatedSalesVolumeUnderTradeAgreementForPeriod(Query, DiscountMarkupCondition, Interval, CalculationParameters)
	
	Query.SetParameter("CurrencyConditions",              DiscountMarkupCondition.RestrictionCurrency);
	
	Query.SetParameter("Terms",                 CalculationParameters.Terms);
	Query.SetParameter("Partner",                    CalculationParameters.Partner);
	Query.SetParameter("ManagementAccountingCurrency", CalculationParameters.ManagementAccountingCurrency);
	Query.SetParameter("DocumentCurrency",            CalculationParameters.DocumentCurrency);
	Query.SetParameter("CurrentDate",                CalculationParameters.CurrentDate);
	Query.SetParameter("Recorder",                CalculationParameters.Recorder);
	
	If Interval.StartDate <> Undefined Then
		Query.SetParameter("PSStartDate", Interval.StartDate);
		Query.SetParameter("StartDate",   Interval.StartDate);
	Else
		Query.SetParameter("PSStartDate", Date(1,1,1));
		Query.SetParameter("StartDate",   "");
	EndIf;
	
	If Interval.EndDate <> Undefined Then
		Query.SetParameter("PSEndDate", Interval.EndDate);
		Query.SetParameter("EndDate",   Interval.EndDate);
	Else
		Query.SetParameter("PSEndDate", CurrentSessionDate());
		Query.SetParameter("EndDate",   "");
	EndIf;
	
EndProcedure

Procedure FillInParametersForDeterminingProductItemItemsForWhichDiscountIsGranted(Query, CalculationParameters, ParametersToFillIn)
	
	If ParametersToFillIn = "All" Or ParametersToFillIn = "CalculationParameters" Then
		Query.SetParameter("CurrentDate", CalculationParameters.CurrentDate);
		Query.SetParameter("Partner", CalculationParameters.Partner);
		Query.SetParameter("Terms", CalculationParameters.Terms);
	EndIf;
	
EndProcedure

Procedure FillInParametersRequestConditionsForOneTimeSaleWithConditionForDocument(Query, DiscountMarkupCondition, CalculationParameters, ParametersToFillIn)

	If ParametersToFillIn = "All" Or ParametersToFillIn = "Cached_" Then
		Query.SetParameter("RestrictionConditionValue"+"Cached_1", DiscountMarkupCondition.RestrictionConditionValue);
	EndIf;
	
	If ParametersToFillIn = "All" Or ParametersToFillIn = "CalculationParameters" Then
		Query.SetParameter("CurrentDate", CalculationParameters.CurrentDate);
	EndIf;
	
EndProcedure

Procedure FillInParametersQueryConditionsForAccumulatedSalesByPartnerForPeriod(Query, DiscountMarkupCondition, Interval, CalculationParameters, ParametersToFillIn)
	
	If ParametersToFillIn = "All" Or ParametersToFillIn = "Cached_" Then
		Query.SetParameter("RestrictionConditionValue"+"Cached_1", DiscountMarkupCondition.RestrictionConditionValue);
	EndIf;
	
	If ParametersToFillIn = "All" Or ParametersToFillIn = "CalculationParameters" Then
		Query.SetParameter("CurrentDate", CalculationParameters.CurrentDate);
	EndIf;
	
EndProcedure

Procedure FillInParametersQueryConditionsForAccumulatedSalesUnderTradeAgreementForPeriod(Query, DiscountMarkupCondition, Interval, CalculationParameters, ParametersToFillIn)

	If ParametersToFillIn = "All" Or ParametersToFillIn = "Cached_" Then
		Query.SetParameter("RestrictionConditionValue"+"Cached_1", DiscountMarkupCondition.RestrictionConditionValue);
	EndIf;
	
	If ParametersToFillIn = "All" Or ParametersToFillIn = "CalculationParameters" Then
		Query.SetParameter("CurrentDate", CalculationParameters.CurrentDate);
	EndIf;
	
EndProcedure

#EndRegion

#Region CheckingTermsOfDiscountsMarkups

Function IntervalOfAccumulationOfSalesVolume(TSRow, CalculationParameters)
	
	StartDate    = Undefined;
	EndDate = EndOfDay(CalculationParameters.CurrentDate);
	
	If TSRow.OptionOfCumulativeQuantityDiscountPeriodDetermination = Enums.OptionsOfEstimatingCumulativeQuantityDiscountPeriod.PreviousPeriod Then
		
		If TSRow.AccumulationPeriod = Enums.Periodicity.HalfYear Then
			StartDate = TMCommonUseClientServer.CalculatePeriodEndDate(
				BeginningOfHalfYear(CalculationParameters.CurrentDate),
				Enums.Periodicity.HalfYear,
				-1 * TSRow.NumberOfAccumulationPeriods);
			EndDate = BeginningOfHalfYear(CalculationParameters.CurrentDate) - 1;
		ElsIf TSRow.AccumulationPeriod = Enums.Periodicity.TenDays Then
			StartDate = TMCommonUseClientServer.CalculatePeriodEndDate(
				BeginningOfDecade(CalculationParameters.CurrentDate),
				Enums.Periodicity.TenDays,
				-1 * TSRow.NumberOfAccumulationPeriods);
			EndDate = BeginningOfDecade(CalculationParameters.CurrentDate) - 1;
		ElsIf TSRow.AccumulationPeriod = Enums.Periodicity.Year Then
			StartDate = TMCommonUseClientServer.CalculatePeriodEndDate(
				BegOfYear(CalculationParameters.CurrentDate),
				Enums.Periodicity.Year,
				-1 * TSRow.NumberOfAccumulationPeriods);
			EndDate = BegOfYear(CalculationParameters.CurrentDate) - 1;
		ElsIf TSRow.AccumulationPeriod = Enums.Periodicity.Quarter Then
			StartDate = TMCommonUseClientServer.CalculatePeriodEndDate(
				BegOfQuarter(CalculationParameters.CurrentDate),
				Enums.Periodicity.Quarter,
				-1 * TSRow.NumberOfAccumulationPeriods);
			EndDate = BegOfQuarter(CalculationParameters.CurrentDate) - 1;
		ElsIf TSRow.AccumulationPeriod = Enums.Periodicity.Month Then
			StartDate = TMCommonUseClientServer.CalculatePeriodEndDate(
				BegOfMonth(CalculationParameters.CurrentDate),
				Enums.Periodicity.Month,
				-1 * TSRow.NumberOfAccumulationPeriods);
			EndDate = BegOfMonth(CalculationParameters.CurrentDate) - 1;
		ElsIf TSRow.AccumulationPeriod = Enums.Periodicity.Week Then
			StartDate = TMCommonUseClientServer.CalculatePeriodEndDate(
				BegOfWeek(CalculationParameters.CurrentDate),
				Enums.Periodicity.Week,
				-1 * TSRow.NumberOfAccumulationPeriods);
			EndDate = BegOfWeek(CalculationParameters.CurrentDate) - 1;
		ElsIf TSRow.AccumulationPeriod = Enums.Periodicity.Day Then
			StartDate = TMCommonUseClientServer.CalculatePeriodEndDate(
				BegOfDay(CalculationParameters.CurrentDate),
				Enums.Periodicity.Day,
				-1  *TSRow.NumberOfAccumulationPeriods);
			EndDate = BegOfDay(CalculationParameters.CurrentDate) - 1;
		EndIf;
		
	ElsIf TSRow.OptionOfCumulativeQuantityDiscountPeriodDetermination = Enums.OptionsOfEstimatingCumulativeQuantityDiscountPeriod.PreviousRollingPeriod Then
		
		StartDate = TMCommonUseClientServer.CalculatePeriodEndDate(
			CalculationParameters.CurrentDate,
			TSRow.AccumulationPeriod,
			-1 * TSRow.NumberOfAccumulationPeriods);
		
	ElsIf TSRow.OptionOfCumulativeQuantityDiscountPeriodDetermination = Enums.OptionsOfEstimatingCumulativeQuantityDiscountPeriod.SinceBeginningOfCurrentPeriod Then
		
		If TSRow.AccumulationPeriod = Enums.Periodicity.Year Then
			StartDate = BegOfYear(CalculationParameters.CurrentDate);
		ElsIf TSRow.AccumulationPeriod = Enums.Periodicity.TenDays Then
			StartDate = BeginningOfDecade(CalculationParameters.CurrentDate);
		ElsIf TSRow.AccumulationPeriod = Enums.Periodicity.HalfYear Then
			StartDate = BeginningOfHalfYear(CalculationParameters.CurrentDate);
		ElsIf TSRow.AccumulationPeriod = Enums.Periodicity.Quarter Then
			StartDate = BegOfQuarter(CalculationParameters.CurrentDate);
		ElsIf TSRow.AccumulationPeriod = Enums.Periodicity.Month Then
			StartDate = BegOfMonth(CalculationParameters.CurrentDate);
		ElsIf TSRow.AccumulationPeriod = Enums.Periodicity.Week Then
			StartDate = BegOfWeek(CalculationParameters.CurrentDate);
		ElsIf TSRow.AccumulationPeriod = Enums.Periodicity.Day Then
			StartDate = BegOfDay(CalculationParameters.CurrentDate);
		EndIf;
		
	EndIf;
	
	Interval = New Structure;
	Interval.Insert("StartDate", StartDate);
	Interval.Insert("EndDate", EndDate);
	
	Return Interval;
	
EndFunction

Function RequestVerificationOfTermsOfService(TSRow, CalculationParameters, ParametersToFillIn)
	
	Query = Undefined;
	
	If TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForOneTimeSalesVolume Then
		
		Query = RequestConditionForOneTimeSaleWithConditionForDocument(TSRow, CalculationParameters, ParametersToFillIn);
		
	ElsIf TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForAccumulatedSalesVolume Then
		
		Interval = IntervalOfAccumulationOfSalesVolume(TSRow, CalculationParameters);
		
		If TSRow.AccumulationOption = Enums.OptionsOfCumulativeDiscountMarkupAccumulation.ByPartner Then
			Query = RequestConditionsForAccumulatedSalesVolumeForPartnerForPeriod(TSRow, Interval, CalculationParameters, ParametersToFillIn);
		ElsIf TSRow.AccumulationOption = Enums.OptionsOfCumulativeDiscountMarkupAccumulation.ByTermsOfSales Then
			Query = RequestTermsAndConditionsForAccumulatedSalesUnderTradeAgreementForPeriod(TSRow, Interval, CalculationParameters, ParametersToFillIn);
		EndIf;
		
	ElsIf TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.LimitationByUserGroup Then
		
		Query = RequestRestrictionByUserGroupCondition(TSRow, CalculationParameters);
		
	ElsIf TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.DuringSale Then
		
		Query = RequestTermsForTimeOfSale(TSRow, CalculationParameters);
		
	ElsIf TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.LoyaltyCardIsNotRegistered Then
		
		Query = RequestConditionsLoyaltyCardNotRegistered(TSRow, CalculationParameters);
		
	ElsIf TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForLoyaltyCard Then
		
		Query = RequestConditionsForLoyaltyCard(TSRow, CalculationParameters);
		
	ElsIf TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.IncludeCustomerInSegment Then
		
		Query = RequestForPartnerSSegmentEntryCondition(TSRow, CalculationParameters);
		
	ElsIf TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForCustomerSBirthday Then
		
		Query = RequestConditionsForBirthday(TSRow, CalculationParameters);
		
	ElsIf TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForPaymentSchedule Then
		
		// Processing the second queue
		
	ElsIf TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForPaymentForm Then
		
		// Processing the second queue
		
	ElsIf TypeOf(TSRow.DiscountMarkupCondition) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		
		ExternalDataProcessor = DiscountsMarkupsCached.ExternalDataProcessorObject(TSRow.DiscountMarkupCondition);
		SetSafeMode(True);
		Query = ExternalDataProcessor.Query(TSRow.ExternalDataProcessorParameters.Get(), CalculationParameters);
		SetSafeMode(False);
		
	EndIf;
	
	Return Query;
	
EndFunction

// Parameters:
// 	DiscountMarkupConditions - ValueTable - consists of:
// 		* Ref - CatalogRef.DiscountMarkupTerms 
// 		* RestrictionConditionValue - Number - Value of the restriction condition
// 		* DiscountMarkupCondition - CatalogRef.AdditionalReportsAndDataProcessors, EnumRef.DiscountMarkupTerms - Provision condition
// 		* OptionOfCumulativeQuantityDiscountPeriodDetermination - EnumRef.OptionsOfEstimatingCumulativeQuantityDiscountPeriod
// 		* AccumulationOption - EnumRef.OptionsOfCumulativeDiscountMarkupAccumulation - Accumulation option
// 		* RestrictionCurrency - CatalogRef.Currencies - Currency restrictions
// 		* DigitalCurrencyCodeRestrictions - String - Currency code
// 		* ComparisonTypeSSL - EnumRef.DiscountMarkupValueComparisonTypes - Type of comparison
// 		* CriteriaOfApplicationLimitationForSalesVolume - EnumRef.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume 
// 		* PaymentSchedule - CatalogRef.PaymentSchedules - Payment schedule
// 		* PaymentMethod - EnumRef.PaymentForms - Form of payment
// 		* ProductSegmentRestrictions - CatalogRef.ProductSegments - Item segment restrictions
// 		* AccumulationPeriod - EnumRef.Periodicity - The frequency with which the cumulative discount (mark-up) is accumulated)
// 		* UsersGroup - CatalogRef.UserGroups - User group
// 		* LoyaltyCardKind - CatalogRef.LoyaltyCardKinds - Type of loyalty card
// 		* NumberOfAccumulationPeriods - Number - Number of accumulation periods
// 		* ItemFilterOption - EnumRef.ItemFilterOptionsForDiscountMarkupCalculation - Item selection option
// 		* StorageOfDataCompositionSettings - ValueStorage - Storage of data layout settings
// 		* ExternalDataProcessorParameters - ValueStorage - External processing parameters
// 		* NumberOfDaysBeforeBirthday - Number - Number of days before your birthday
// 		* NumberOfDaysAfterBirthday - Number - Number of days after your birthday
// 		* IncludeCurrentSaleInAccumulatedSalesVolume - Boolean - Include the current sale in the accumulated sales volume
// 		* ApplyVariants - Boolean - Take into account the characteristics
// 		* PartnersSegment - CatalogRef.PartnersSegments - The discount (mark-up) applies to item items from this segment.
// 	DiscountsMarkups - Array of ValueTreeRow - See CreateDiscountTree
// 	CalculationParameters - See CalculationParameters
// 	TempTablesManager - TempTablesManager
// 	
// 	Returns:
// 		See EmptyTableConditionValidationResult
//
Function FulfillTermsOfServiceRequests(DiscountMarkupConditions, DiscountsMarkups, CalculationParameters, TempTablesManager)
	
	Package = CreateRequestPackage();
	Package.Query.TempTablesManager = TempTablesManager;
	
	ProcessingSecondQueue = New Array; // See FulfillTermsOfServiceRequests.DiscountMarkupConditions
	
	// Preparation of tables for collecting data for accumulated sales
	DataAboutTables = New Map;
	For Each TSRow In DiscountMarkupConditions Do
		
		If Not TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForAccumulatedSalesVolume Then
			Continue;
		EndIf;
		
		Interval = IntervalOfAccumulationOfSalesVolume(TSRow, CalculationParameters);
		
		TempTableName = TemporaryTableNameAccumulatedSales(TSRow, Interval);
		
		If DataAboutTables.Get(TempTableName) <> Undefined Then
			Continue;
		EndIf;
		
		DataAboutTables.Insert(TempTableName, True);
		
		If TSRow.AccumulationOption = Enums.OptionsOfCumulativeDiscountMarkupAccumulation.ByPartner Then
			Query = QueryAccumulatedSalesVolumeForPartnerForPeriod(TSRow, Interval, CalculationParameters);
		ElsIf TSRow.AccumulationOption = Enums.OptionsOfCumulativeDiscountMarkupAccumulation.ByTermsOfSales Then
			Query = QueryAccumulatedSalesUnderTradeAgreementForPeriod(TSRow, Interval, CalculationParameters);
		EndIf;
		
		Var_Key = Undefined;
		DeleteTemporaryTables_ = False;
		TransformParameters = True;
		
		RequestPackageInsertRequestIntoPackage(
			Query, Package, Var_Key,
			DeleteTemporaryTables_, TransformParameters);
		
	EndDo;
	
	For Each TSRow In DiscountMarkupConditions Do
		
		Var_Key = TSRow.Ref;
		
		UseCachedRequest = False;
		If TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForOneTimeSalesVolume Then
			UseCachedRequest = True;
		ElsIf TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForAccumulatedSalesVolume Then
			UseCachedRequest = True;
		EndIf;
		
		If UseCachedRequest Then
			
			If TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForOneTimeSalesVolume
				And TSRow.RestrictionCurrency <> CalculationParameters.DocumentCurrency Then
				
				Settings = Undefined;
			Else
				Settings = TSRow.StorageOfDataCompositionSettings.Get();
			EndIf;
			
			If Settings <> Undefined And Settings.Property("Query") Then
			
				NumberOfRequestsPerBatch = Settings.Query.NumberOfRequestsPerBatch;
				ResultQueryIndex   = Settings.Query.ResultQueryIndex;
				QueryText              = Settings.Query.QueryText;
				
				Interval = IntervalOfAccumulationOfSalesVolume(TSRow, CalculationParameters);
				
				If TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForAccumulatedSalesVolume Then
					TempTableName = TemporaryTableNameAccumulatedSales(TSRow, Interval);
					QueryText = StrReplace(QueryText, "RawData", TempTableName);
				EndIf;
				
				Query = New Query(QueryText);
				For Each Parameter In Settings.Query.Parameters Do
					Query.SetParameter(Parameter.Key, Parameter.Value);
				EndDo;
				
				If TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForAccumulatedSalesVolume Then
					If TSRow.AccumulationOption = Enums.OptionsOfCumulativeDiscountMarkupAccumulation.ByPartner Then
						FillInParametersQueryConditionsForAccumulatedSalesByPartnerForPeriod(Query, TSRow, Interval, CalculationParameters, "CalculationParameters");
					ElsIf TSRow.AccumulationOption = Enums.OptionsOfCumulativeDiscountMarkupAccumulation.ByTermsOfSales Then
						FillInParametersQueryConditionsForAccumulatedSalesUnderTradeAgreementForPeriod(Query, TSRow, Interval, CalculationParameters, "CalculationParameters");
					EndIf;
				ElsIf TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForOneTimeSalesVolume Then
					FillInParametersRequestConditionsForOneTimeSaleWithConditionForDocument(Query, TSRow, CalculationParameters, "CalculationParameters");
				EndIf;
				
				DeleteTemporaryTables_ = False;
				TransformParameters = True;
				RequestPackageInsertRequestIntoPackage(
					Query, Package, Var_Key,
					DeleteTemporaryTables_, TransformParameters,
					NumberOfRequestsPerBatch,
					ResultQueryIndex);
					
			Else
				
				DeleteTemporaryTables_ = True;
				TransformParameters = True;
				
				Query = RequestVerificationOfTermsOfService(TSRow, CalculationParameters, "All");
				RequestPackageInsertRequestIntoPackage(
					Query, Package, Var_Key,
					DeleteTemporaryTables_, TransformParameters);
				
			EndIf;
			
		Else
			
			Query = RequestVerificationOfTermsOfService(TSRow, CalculationParameters, "All");
			
			If Query = Undefined Then
				ProcessingSecondQueue.Add(TSRow);
			Else
				
				If TypeOf(TSRow.DiscountMarkupCondition) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
					DeleteTemporaryTables_ = True;
				Else
					DeleteTemporaryTables_ = False;
				EndIf;
				
				TransformParameters = True;
				
				RequestPackageInsertRequestIntoPackage(
					Query, Package, Var_Key,
					DeleteTemporaryTables_, TransformParameters);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each TreeRow In DiscountsMarkups Do
		
		If TreeRow.ItemFilterOption = Enums.ItemFilterOptionsForDiscountMarkupCalculation.WithoutRestrictions
			And Not TreeRow.AdditionalFilterIsSet Then
			Continue;
		EndIf;
		
		Var_Key = TreeRow.Ref;
		
		Settings = TreeRow.StorageOfDataCompositionSettings.Get();
		
		If Settings <> Undefined And Settings.Property("Query") Then
		
			NumberOfRequestsPerBatch = Settings.Query.NumberOfRequestsPerBatch;
			ResultQueryIndex   = Settings.Query.ResultQueryIndex;
			QueryText              = Settings.Query.QueryText;
			
			Query = New Query(QueryText);
			For Each Parameter In Settings.Query.Parameters Do
				Query.SetParameter(Parameter.Key, Parameter.Value);
			EndDo;
			
			DeleteTemporaryTables_ = False;
			TransformParameters = True;
			FillInParametersForDeterminingProductItemItemsForWhichDiscountIsGranted(Query, CalculationParameters, "CalculationParameters");
			RequestPackageInsertRequestIntoPackage(
				Query, Package, Var_Key,
				DeleteTemporaryTables_, TransformParameters,
				NumberOfRequestsPerBatch,
				ResultQueryIndex);
			
		Else
			
			DeleteTemporaryTables_ = True;
			TransformParameters = True;
			
			Query = RequestToDefineProductItemsForWhichDiscountIsGranted(TreeRow, CalculationParameters, "All");
			RequestPackageInsertRequestIntoPackage(
				Query, Package, Var_Key,
				DeleteTemporaryTables_, TransformParameters);
			
		EndIf;
		
	EndDo;
	
	QueryBatchExecute(Package);
	
	VT = EmptyTableConditionValidationResult();
	
	For Each TSRow In ProcessingSecondQueue Do
		
		If TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForPaymentSchedule Then
			
			MultiplicityOfExecution = CheckConditionForPaymentSchedule(TSRow, CalculationParameters);
			
		ElsIf TSRow.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForPaymentForm Then
			
			MultiplicityOfExecution = CheckConditionForPaymentForm(TSRow, CalculationParameters);
			
		ElsIf TypeOf(TSRow.DiscountMarkupCondition) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
			
			ExternalDataProcessor = DiscountsMarkupsCached.ExternalDataProcessorObject(TSRow.DiscountMarkupCondition);
			SetSafeMode(True);
			MultiplicityOfExecution = ExternalDataProcessor.CheckTheCondition(TSRow.ExternalDataProcessorParameters.Get(), CalculationParameters);
			SetSafeMode(False);
			
		EndIf;
		
		If MultiplicityOfExecution = 0 Then
			Continue;
		EndIf;
		
		NewRow = VT.Add();
		NewRow.Ref              = TSRow.Ref; 
		NewRow.ConnectionKey           = -1;
		NewRow.MultiplicityOfExecution = MultiplicityOfExecution;
		
	EndDo;
	
	TableFulfilledConditions = CombineResults(Package, VT);
	
	Return TableFulfilledConditions;
	
EndFunction

Function CombineResults(QueryBatch, Table)
	
	VT = EmptyTableConditionValidationResult();
	
	TypeOfDiscountMarkup = Type("CatalogRef.DiscountsMarkups");
	
	For Each KeyAndValue In QueryBatch.MatchingQueryAndResultTableNumber Do
		
		ThereIsColumnIndicatorValue = Undefined;
		
		QueryResult = QueryBatch.QueryResult[KeyAndValue.Value-1]; // QueryResult
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			If ThereIsColumnIndicatorValue = Undefined Then
				ThereIsColumnIndicatorValue = TMCommonUseClientServer.HasObjectAttribute(Selection, "IndicatorValue");
			EndIf;
			
			NewRow = VT.Add();
			NewRow.Ref = KeyAndValue.Key;
			If TypeOf(KeyAndValue.Key) = TypeOfDiscountMarkup Then
				NewRow.ConnectionKey = Selection.ConnectionKey;
			Else
				NewRow.ConnectionKey = -1;
			EndIf;
			NewRow.MultiplicityOfExecution = Selection.MultiplicityOfExecution;
			
			If ThereIsColumnIndicatorValue Then
				NewRow.IndicatorValue = Selection.IndicatorValue;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	For Each TSRow In Table Do
		FillPropertyValues(VT.Add(), TSRow);
	EndDo;
	
	Return VT;
	
EndFunction

// Parameters:
// 	TreeRow - ValueTreeRow - See CreateDiscountTree. contains including:
// 		* ConditionParameters_ - Structure - contains including:
// 			** ConditionsAreFulfilled - Boolean
// 			** LineCodes - Array
// 			** ConditionsByLine - Structure - contains including:
// 				*** ConditionVerificationTable - ValueTable
// 				*** MatchingConditionsToColumnsInConditionVerificationTable - Map
// 			** ThereAreConditionsOnLine - Boolean
// 			** TableOfConditions - ValueTable
// 	FulfilledConditions - See EmptyTableConditionValidationResult
// 
Function CheckConditions(TreeRow, FulfilledConditions, Conditions)
	
	TreeRow.ConditionParameters_.Insert("ConditionsAreFulfilled",    True);
	TreeRow.ConditionParameters_.Insert("LineCodes",           New Array);
	TreeRow.ConditionParameters_.Insert("ConditionsByLine",     New Structure);
	TreeRow.ConditionParameters_.Insert("ThereAreConditionsOnLine", False);
	TreeRow.ConditionParameters_.Insert("TableOfConditions",      New ValueTable);
	
	// A service table for temporary storage of the results of verification of the terms of provision.
	TreeRow.ConditionParameters_.TableOfConditions.Columns.Add("DiscountMarkupCondition", New TypeDescription("CatalogRef.DiscountMarkupTerms,CatalogRef.DiscountsMarkups"));
	TreeRow.ConditionParameters_.TableOfConditions.Columns.Add("ScopeOfRestriction",    New TypeDescription("EnumRef.OptionsOfLimitationAreasOfDiscountsAndMarkups"));
	TreeRow.ConditionParameters_.TableOfConditions.Columns.Add("Completed2");
	TreeRow.ConditionParameters_.TableOfConditions.Columns.Add("IndicatorValue");
	TreeRow.ConditionParameters_.TableOfConditions.Columns.Add("MultiplicityOfExecution",   New TypeDescription("Number"));
	
	// The table is used to check the fulfillment of conditions by row.
	// If the discount has conditions for a row, then a column will be created for these conditions in the table.
	TreeRow.ConditionParameters_.ConditionsByLine.Insert("ConditionVerificationTable", New ValueTable);
	TreeRow.ConditionParameters_.ConditionsByLine.ConditionVerificationTable.Columns.Add("ConnectionKey");
	TreeRow.ConditionParameters_.ConditionsByLine.ConditionVerificationTable.Indexes.Add("ConnectionKey");
	
	TreeRow.ConditionParameters_.ConditionsByLine.Insert("MatchingConditionsToColumnsInConditionVerificationTable", New Map);
	
	// Service parameters
	ConditionValidationTableIsUsed      = False;
	ThisIsFirstConditionOfConditionValidationTable  = True;
	NumberOfColumnsInConditionVerificationTable = 0;
	
	For Each Condition In Conditions.FindRows(New Structure("DiscountMarkup", TreeRow.Ref)) Do
		
		RowTableOfConditions = TreeRow.ConditionParameters_.TableOfConditions.Add();
		RowTableOfConditions.DiscountMarkupCondition = Condition.DiscountMarkupCondition;
		If TypeOf(Condition.DiscountMarkupCondition) = Type("CatalogRef.DiscountMarkupTerms") Then
			RowTableOfConditions.ScopeOfRestriction = Enums.OptionsOfLimitationAreasOfDiscountsAndMarkups.InDocument;
		Else
			TreeRow.ConditionParameters_.ThereAreConditionsOnLine = True;
			RowTableOfConditions.ScopeOfRestriction = Enums.OptionsOfLimitationAreasOfDiscountsAndMarkups.AtRow;
		EndIf;
		
		FoundRows = FulfilledConditions.FindRows(New Structure("Ref", Condition.DiscountMarkupCondition));
		
		If FoundRows.Count() = 0 Then
			
			// The condition is not met.
			RowTableOfConditions.Completed2 = False;
			
			TreeRow.ConditionParameters_.ConditionsAreFulfilled = False;
			
			RowTableOfConditions.MultiplicityOfExecution = 0;
			
		ElsIf FoundRows.Count() = 1
			And FoundRows[0].ConnectionKey = -1 Then
			
			FoundRow = FoundRows[0];
			If FoundRow.MultiplicityOfExecution = 0 Then
				
				RowTableOfConditions.Completed2 = False;
				// The condition is not met.
				RowTableOfConditions.IndicatorValue = FoundRow.IndicatorValue;
				
				TreeRow.ConditionParameters_.ConditionsAreFulfilled = False;
				
			Else
				
				RowTableOfConditions.Completed2 = True;
				// The condition is met. The condition does not depend on specific strings.
				RowTableOfConditions.IndicatorValue = FoundRow.IndicatorValue;
				RowTableOfConditions.MultiplicityOfExecution = FoundRow.MultiplicityOfExecution;
				
			EndIf;
			
		Else
			
			NumberOfColumnsInConditionVerificationTable = NumberOfColumnsInConditionVerificationTable + 1;
			ColumnTitle = "Condition" + NumberOfColumnsInConditionVerificationTable;
			
			TreeRow.ConditionParameters_.ConditionsByLine.MatchingConditionsToColumnsInConditionVerificationTable.Insert(Condition.DiscountMarkupCondition, ColumnTitle);
			TreeRow.ConditionParameters_.ConditionsByLine.ConditionVerificationTable.Columns.Add(ColumnTitle, New TypeDescription("Boolean"));
			
			Counter = 0;
			TotalMultiplicityOfExecution = 0;
			For Each FoundRow In FoundRows Do
				
				If FoundRow.MultiplicityOfExecution <> 0 Then
					Counter = Counter + 1;
				EndIf;
				
				ConditionValidationTableIsUsed = True;
				
				FoundRowsInConditionValidationTable = TreeRow.ConditionParameters_.ConditionsByLine.ConditionVerificationTable.Find(FoundRow.ConnectionKey, "ConnectionKey");
				If FoundRowsInConditionValidationTable <> Undefined Then
					FoundRowsInConditionValidationTable[ColumnTitle] = True;
				Else
					If ThisIsFirstConditionOfConditionValidationTable Then
						NewRow1 = TreeRow.ConditionParameters_.ConditionsByLine.ConditionVerificationTable.Add();
						NewRow1.ConnectionKey = FoundRow.ConnectionKey;
						NewRow1[ColumnTitle] = True;
					EndIf;
				EndIf;
				
				If FoundRow.MultiplicityOfExecution > 0 Then
					TotalMultiplicityOfExecution = TotalMultiplicityOfExecution + FoundRow.MultiplicityOfExecution;
				EndIf;
				
			EndDo;
			
			RowTableOfConditions.Completed2 = (Counter > 0);
			// The condition is met if several rows are found that have passed the condition check.
			
			If Not RowTableOfConditions.Completed2 Then
				TreeRow.ConditionParameters_.ConditionsAreFulfilled = False;
			EndIf;
			
			RowTableOfConditions.MultiplicityOfExecution = TotalMultiplicityOfExecution;
			
		EndIf;
		
		If ConditionValidationTableIsUsed Then
			ThisIsFirstConditionOfConditionValidationTable = False;
		EndIf;
		
	EndDo;
	
	// Fill in the line codes...
	If TreeRow.ConditionParameters_.ConditionsAreFulfilled Then
		
		If TreeRow.ConditionParameters_.ConditionsByLine.MatchingConditionsToColumnsInConditionVerificationTable.Count() > 0 Then
			
			Filter = New Structure;
			For Each KeyAndValue In TreeRow.ConditionParameters_.ConditionsByLine.MatchingConditionsToColumnsInConditionVerificationTable Do
				Filter.Insert(KeyAndValue.Value, True);
			EndDo;
			
			FoundRows = TreeRow.ConditionParameters_.ConditionsByLine.ConditionVerificationTable.FindRows(Filter);
			For Each SpecificationRow In FoundRows Do
				TreeRow.ConditionParameters_.LineCodes.Add(SpecificationRow.ConnectionKey);
			EndDo;
			
		EndIf;
		
	EndIf;

EndFunction

Procedure CheckConditionsRecursively(DiscountTree, DiscountTreeRows, Conditions, FulfilledConditions)
	
	DiscountTree.Columns.Add("DiscountMarkupConditions", New TypeDescription("ValueTable"));
	DiscountTree.Columns.Add("CalculationResult2",      New TypeDescription("ValueTable"));
	DiscountTree.Columns.Add("ConditionParameters_",      New TypeDescription("Structure"));
	
	For Each TreeRow In DiscountTreeRows Do
		
		CheckConditions(TreeRow, FulfilledConditions, Conditions);
		
	EndDo;
	
EndProcedure

Procedure PrepareQueryTextForCheckingConditionAndCalculatingMultiplicity(QueryText, DiscountMarkupCondition)
	
	ConditionText = "";
	IndicatorText = "";
	If DiscountMarkupCondition.CriteriaOfApplicationLimitationForSalesVolume = Enums.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.Sum Then
		If DiscountMarkupCondition.ComparisonTypeSSL = Enums.DiscountMarkupValueComparisonTypes.NotLessThan Then
			ConditionText = "ISNULL(Goods.Sum, 0) >= &RestrictionConditionValue"+"Cached_1";
		Else
			ConditionText = "ISNULL(Goods.Sum, 0) <= &RestrictionConditionValue"+"Cached_1";
		EndIf;
		IndicatorText = "ISNULL(Goods.Sum, 0)";
	Else
		If DiscountMarkupCondition.ComparisonTypeSSL = Enums.DiscountMarkupValueComparisonTypes.NotLessThan Then
			ConditionText = "ISNULL(Goods.Count, 0) >= &RestrictionConditionValue"+"Cached_1"
		Else
			ConditionText = "ISNULL(Goods.Count, 0) <= &RestrictionConditionValue"+"Cached_1"
		EndIf;
		IndicatorText = "ISNULL(Goods.Count, 0)";
	EndIf;
	QueryText = StrReplace(QueryText, "&ConditionText", ConditionText);
	QueryText = StrReplace(QueryText, "&TextIndicatorValue", IndicatorText);
	
	MultiplicityText = "";
	If DiscountMarkupCondition.CriteriaOfApplicationLimitationForSalesVolume = Enums.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.Sum Then
		
		If DiscountMarkupCondition.ComparisonTypeSSL = Enums.DiscountMarkupValueComparisonTypes.NotLessThan Then
			If DiscountMarkupCondition.RestrictionConditionValue <> 0 Then
				MultiplicityText = "CASE WHEN ISNULL(Goods.Sum, 0) > 0 THEN CAST((ISNULL(Goods.Sum, 0) / &ValueOfRestrictionConditionIsCached - 0.5) AS NUMBER(15,0)) ELSE 0 END";
			Else
				MultiplicityText = "
				|CASE
				|	WHEN ISNULL(Goods.Sum, 0) > 0 THEN
				|		1
				|	ELSE
				|		0
				|END";
			EndIf;
		Else
			MultiplicityText = "
			|CASE
			|	WHEN ISNULL(Goods.Sum, 0) <= &ValueOfRestrictionConditionIsCached THEN
			|		1
			|	ELSE
			|		0
			|END";
		EndIf;
		MultiplicityText = StrReplace(MultiplicityText, "&ValueOfRestrictionConditionIsCached", "&RestrictionConditionValue"+"Cached_1");
	ElsIf DiscountMarkupCondition.CriteriaOfApplicationLimitationForSalesVolume = Enums.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.Count
		Or DiscountMarkupCondition.CriteriaOfApplicationLimitationForSalesVolume = Enums.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.NumberOfSimilarOnes
		Or DiscountMarkupCondition.CriteriaOfApplicationLimitationForSalesVolume = Enums.CriteriaOfLimitationOfUseOfDiscountsAndMarkupsForSalesVolume.DifferentItemsCount Then
		
		If DiscountMarkupCondition.ComparisonTypeSSL = Enums.DiscountMarkupValueComparisonTypes.NotLessThan Then
			If DiscountMarkupCondition.RestrictionConditionValue <> 0 Then
				MultiplicityText = "CASE WHEN ISNULL(Goods.Count, 0) > 0 THEN CAST((ISNULL(Goods.Count, 0) / &ValueOfRestrictionConditionIsCached - 0.5) AS NUMBER(15,0)) ELSE 0 END";
			Else
				MultiplicityText = "
				|CASE
				|	WHEN ISNULL(Goods.Count, 0) > 0 THEN
				|		1
				|	ELSE
				|		0
				|END";
			EndIf
		Else
			MultiplicityText = "
			|CASE
			|	WHEN ISNULL(Goods.Count, 0) <= &ValueOfRestrictionConditionIsCached THEN
			|		1
			|	ELSE
			|		0
			|END";
		EndIf;
		MultiplicityText = StrReplace(MultiplicityText, "&ValueOfRestrictionConditionIsCached", "&RestrictionConditionValue"+"Cached_1");
	Else
		MultiplicityText = "0";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&MultiplicityText", MultiplicityText);
	
EndProcedure

#EndRegion

#Region Sets

Function DataOnProductsAndSets(QueryText, QueryOptions, UseSets) Export
	
	
	SetFields =
	"	Goods.ProductsInSet   AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|";
	
	Fields =
	"	ProductKitConfigurations.Ref  AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption                  AS SetPricingOption,
	|	Table.ProductsInSet   AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|";
	
	Join =
	"	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|";
	
	RequestSets =
	";
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ProductsInSet   AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	MIN(Table.ConnectionKey)   AS ConnectionKey,
	|	SUM(Table.Price * Table.NumberOfPackages) AS Sum
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	AND Table.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),
	|	                                      VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|
	|GROUP BY
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CASE WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|		AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS MainComponent,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products   AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	FALSE AS MainComponent,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM Goods AS T)
	|
	|GROUP BY
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE null
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|GROUP BY
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.ConnectionKey                         AS ConnectionKey,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                             AS Sum
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|		AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ConnectionKey,
	|	Table.ProductsInSet AS Products,
	|	Table.ItemVariantOfSet AS Characteristic,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	VALUE(Catalog.TypesOfPrices.EmptyRef) AS PriceKind,
	|	Table.ProductsInSet.PriceGroup AS PriceGroup,
	|	Table.Count,
	|	Table.NumberOfPackages,
	|	CASE WHEN Table.NumberOfPackages <> 0 THEN
	|		Table.Sum / Table.NumberOfPackages
	|	ELSE
	|		0
	|	END AS Price,
	|	Table.Sum
	|FROM
	|	TemporaryTableSets AS Table
	|
	|UNION ALL
	|
	|SELECT
	|	Table.ConnectionKey,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	Table.Series,
	|	Table.Warehouse,
	|	Table.PriceKind,
	|	Table.PriceGroup,
	|	Table.Count,
	|	Table.NumberOfPackages,
	|	Table.Price,
	|	Table.Sum
	|FROM
	|	Goods AS Table
	|WHERE
	|	Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|	OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	   AND Table.SetPricingOption = VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices))
	|;
	|
	|SELECT
	|	Table.ConnectionKey   AS ComponentCommunicationKey,
	|	TemporaryTableSets.ConnectionKey AS SetCommunicationKey
	|FROM
	|	Goods AS Table
	|		INNER JOIN TemporaryTableSets AS TemporaryTableSets
	|		ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|		AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	AND Table.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),
	|	                                      VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|TOTALS BY
	|	TemporaryTableSets.ConnectionKey
	|";
	
	If UseSets Then
		QueryText = StrReplace(QueryText, ",&TempTableName",	"INTO Goods");
		QueryText = StrReplace(QueryText, "&SetFields,",			SetFields);
		QueryText = StrReplace(QueryText, "&TableFields,",			Fields);
		QueryText = StrReplace(QueryText, ",&Join",			Join);
		QueryText = StrReplace(QueryText, "; SELECT &RequestSets",	RequestSets);
	Else
		QueryText = StrReplace(QueryText, ",&TempTableName",	"");
		QueryText = StrReplace(QueryText, "&SetFields,",			"");
		QueryText = StrReplace(QueryText, "&TableFields,",			"");
		QueryText = StrReplace(QueryText, ",&Join",			"");
		QueryText = StrReplace(QueryText, "; SELECT &RequestSets",	"");
	EndIf;
	
	Query = New Query(QueryText);
	For Each KeyValue In QueryOptions Do
		Query.SetParameter(KeyValue.Key, KeyValue.Value);
	EndDo;
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Goods");
	ReturnValue.Insert("MatchingKeys");
	If UseSets Then
		QueryResult = Query.ExecuteBatch();
		ReturnValue.Goods             = QueryResult[QueryResult.Count() - 2].Unload();
		ReturnValue.MatchingKeys = QueryResult[QueryResult.Count() - 1].Unload(QueryResultIteration.ByGroups);
	Else
		ReturnValue.Goods = Query.Execute().Unload();
	EndIf;
	
	Return ReturnValue;
	
EndFunction

Procedure DistributeKitDiscountsByComponents(AppliedDiscountsMarkups, MatchingKeys, GoodsTable)
	
	For Each TSRow In AppliedDiscountsMarkups.DiscountTree.Rows Do
		DistributeDataTablesByComponent(TSRow, MatchingKeys, GoodsTable);
	EndDo;
	
	For Each StringSet In MatchingKeys.Rows Do
		
		ForDeletion = New Array;
		
		FoundRows = AppliedDiscountsMarkups.TableDiscountsMarkups.FindRows(New Structure("ConnectionKey", StringSet.SetCommunicationKey));
		For Each DiscountRow In FoundRows Do
			
			AmountForAllocation = DiscountRow.Sum;
			
			Sum = 0;
			For Each StringComponents In StringSet.Rows Do
				TSRow = GoodsTable.Find(StringComponents.ComponentCommunicationKey, "ConnectionKey");
				Sum = Sum + TSRow.NumberOfPackages*TSRow.Price;
			EndDo;
			
			NewRow = Undefined;
			
			For Each StringComponents In StringSet.Rows Do
				
				TSRow = GoodsTable.Find(StringComponents.ComponentCommunicationKey, "ConnectionKey");
				
				NewRow = AppliedDiscountsMarkups.TableDiscountsMarkups.Add();
				FillPropertyValues(NewRow, DiscountRow,,"ConnectionKey,Sum");
				
				NewRow.ConnectionKey = StringComponents.ComponentCommunicationKey;
				If Sum <> 0 Then
					NewRow.Sum = Round((TSRow.NumberOfPackages*TSRow.Price)/Sum*AmountForAllocation, 2);
				EndIf;
				AmountForAllocation = AmountForAllocation - NewRow.Sum;
				Sum = Sum - TSRow.NumberOfPackages*TSRow.Price;
				
				If AmountForAllocation = 0 Then
					Break;
				EndIf;
				
			EndDo;

			If AmountForAllocation <> 0 And Not NewRow = Undefined Then
				NewRow.Sum = NewRow.Sum + AmountForAllocation;
			EndIf;
			
			ForDeletion.Add(DiscountRow);
			
		EndDo;
		
		For Each TSRow In ForDeletion Do
			AppliedDiscountsMarkups.TableDiscountsMarkups.Delete(TSRow);
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure DistributeDataTablesByComponent(TableRow, MatchingKeys, GoodsTable)
	
	For Each StringSet In MatchingKeys.Rows Do
		
		ForDeletion = New Array;
		
		FoundRows = TableRow.CalculationResult2.FindRows(New Structure("ConnectionKey", StringSet.SetCommunicationKey));
		For Each DiscountRow In FoundRows Do
			
			AmountForAllocation = DiscountRow.Sum;
			
			Sum = 0;
			For Each StringComponents In StringSet.Rows Do
				TSRow = GoodsTable.Find(StringComponents.ComponentCommunicationKey, "ConnectionKey");
				Sum = Sum + TSRow.NumberOfPackages*TSRow.Price;
			EndDo;
			
			For Each StringComponents In StringSet.Rows Do
				
				TSRow = GoodsTable.Find(StringComponents.ComponentCommunicationKey, "ConnectionKey");
				
				NewRow = TableRow.CalculationResult2.Add();
				FillPropertyValues(NewRow, DiscountRow,,"ConnectionKey,Sum,Details");
				
				NewRow.ConnectionKey = StringComponents.ComponentCommunicationKey;
				If Sum <> 0 Then
					NewRow.Sum = (TSRow.NumberOfPackages*TSRow.Price)/Sum*AmountForAllocation;
				EndIf;
				AmountForAllocation = AmountForAllocation - NewRow.Sum;
				Sum = Sum - TSRow.NumberOfPackages*TSRow.Price;
				
				NewRow.Details = DiscountRow.Details.CopyColumns();
				For Each TSRow In DiscountRow.Details Do
					NewDecryptionLine = NewRow.Details.Add();
					NewDecryptionLine.DiscountMarkup = TSRow.DiscountMarkup;
					If DiscountRow.Sum <> 0 Then
						NewDecryptionLine.Sum = TSRow.Sum * NewRow.Sum / DiscountRow.Sum;
					EndIf;
				EndDo;
				
			EndDo;
			
			ForDeletion.Add(DiscountRow);
			
		EndDo;
		
		For Each TSRow In ForDeletion Do
			TableRow.CalculationResult2.Delete(TSRow);
		EndDo;
		
	EndDo;
	
	For Each TSRow In TableRow.Rows Do
		DistributeDataTablesByComponent(TSRow, MatchingKeys, GoodsTable);
	EndDo;
	
EndProcedure

#EndRegion

#Region GeneralProceduresFunctionsOfDiscountConditionsForms

// Checking the need to register for an update.
// 
// Parameters:
//  LinkToCheck  - CatalogObject.DiscountsMarkups, CatalogObject.DiscountMarkupTerms - Link for verification
//  VerificationText  - String - Tex of occurrence in the request
// 
// Returns:
//  Boolean - True, Registration is required
Function RegistrationRequired(LinkToCheck, VerificationText = "") Export
	
	// let's check the correctness of the saved filter, if there is one
	Try
		FilterDataByProductType(LinkToCheck, "");
	Except
		Return False;
	EndTry;
	StorageOfDataCompositionSettings = LinkToCheck.GetObject().StorageOfDataCompositionSettings; // ValueStorage
	DataCompositionSettings = StorageOfDataCompositionSettings.Get();
	If ValueIsFilled(DataCompositionSettings) 
		And TypeOf(DataCompositionSettings) = Type("Structure") 
		And DataCompositionSettings.Property("Query") 
		And DataCompositionSettings.Query.Property("QueryText") Then
		
		If IsBlankString(VerificationText) Then
			Return Not IsBlankString(DataCompositionSettings.Query.QueryText);
		Else
			Return (StrFind(DataCompositionSettings.Query.QueryText, VerificationText) = 0);
		EndIf;
		
	Else
		Return False;
	EndIf;
	
EndFunction

// Refresh the cached request.
// 
// Parameters:
//  CurrentObject - CatalogObject.DiscountsMarkups, CatalogObject.DiscountMarkupTerms - Object of change
Procedure UpdateCachedRequest(CurrentObject) Export

	ShapeStructure_ = New Structure;
	ShapeStructure_.Insert("AddressOfExternalDataProcessorSettings","");
	ShapeStructure_.Insert("SettingsComposerFilterByProducts",New DataCompositionSettingsComposer);
	ShapeStructure_.Insert("SettingsComposerAdditionalConditions",New DataCompositionSettingsComposer);
	
	DataCompositionSettings = CurrentObject.StorageOfDataCompositionSettings.Get();
	If ValueIsFilled(DataCompositionSettings) Then
		If TypeOf(DataCompositionSettings) = Type("Structure") And DataCompositionSettings.Property("Query") Then
			DataCompositionSettings.Delete("Query");
		EndIf;
	Else
		DataCompositionSettings = New Structure();
	EndIf;
	
	// Place settings without a cached request.
	CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(DataCompositionSettings);
	
	InsertCachedQuery(DataCompositionSettings, CurrentObject);
	
	CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(DataCompositionSettings);

EndProcedure

Procedure InsertCachedQuery(DataCompositionSettings, CurrentObject)
	
	CalculationParameters = CalculationParameters();
	If TypeOf(CurrentObject.Ref) = Type("CatalogRef.DiscountMarkupTerms") Then
		UseCachedRequest = False;
		If CurrentObject.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForOneTimeSalesVolume Then
			UseCachedRequest = True;
		ElsIf CurrentObject.DiscountMarkupCondition = Enums.DiscountMarkupTerms.ForAccumulatedSalesVolume Then
			UseCachedRequest = True;
		EndIf;
		If UseCachedRequest Then
			Query = RequestVerificationOfTermsOfService(CurrentObject, CalculationParameters, "Cached_");
		EndIf;
	Else
		Query = RequestToDefineProductItemsForWhichDiscountIsGranted(CurrentObject, CalculationParameters, "Cached_");
	EndIf;
	
	If Query <> Undefined Then
		
		DeleteTemporaryTables(Query);
		
		Subqueries = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Query.Text, ";");
		NumberOfRequestsPerBatch = Subqueries.Count();
		ResultQueryIndex = 0;
		For IndexOf = -(NumberOfRequestsPerBatch - 1) To 0 Do
			If Find(Subqueries[-IndexOf], "#123456789#") > 0 Then
				ResultQueryIndex = -IndexOf + 1;
			EndIf;
		EndDo;
		
		DataCompositionSettings.Insert("Query", New Structure);
		DataCompositionSettings.Query.Insert("Parameters", New Structure);
		For Each Parameter In Query.Parameters Do
			If StrFind(Parameter.Key, "Cached_1") > 0 Then
				ParameterName = RequestPackageConvertParameter(Query.Text, Parameter.Key, Parameter.Value, Undefined);
				If ParameterName <> Undefined Then
					DataCompositionSettings.Query.Parameters.Insert(ParameterName, Parameter.Value);
				EndIf;
			EndIf;
		EndDo;
		DataCompositionSettings.Query.Insert("QueryText", Query.Text);
		DataCompositionSettings.Query.Insert("ResultQueryIndex",   ResultQueryIndex);
		DataCompositionSettings.Query.Insert("NumberOfRequestsPerBatch", NumberOfRequestsPerBatch);
		
	EndIf;
	
EndProcedure

// Handler for the event before writing to the Server.
//
// Parameters:
// 	Form - ClientApplicationForm - Form
// 	CurrentObject - CatalogObject.DiscountsMarkups, CatalogObject.DiscountMarkupTerms - 
// 	FieldName - String - field name
// 
Procedure BeforeWriteAtServer(Form, CurrentObject, FieldName) Export
	
	If TypeOf(CurrentObject[FieldName]) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		If ValueIsFilled(Form.AddressOfExternalDataProcessorSettings) Then
			CurrentObject.ExternalDataProcessorParameters = New ValueStorage(GetFromTempStorage(Form.AddressOfExternalDataProcessorSettings));
		Else
			CurrentObject.ExternalDataProcessorParameters = New ValueStorage(Undefined);
		EndIf;
	Else
		CurrentObject.ExternalDataProcessorParameters = New ValueStorage(Undefined);
	EndIf;
	
	DataCompositionSettings = New Structure;
	DataCompositionSettings.Insert("FilterRemainingGoodsByShelfLives", Form.SettingsComposerFilterByProducts.GetSettings());
	If TypeOf(CurrentObject.Ref) = Type("CatalogRef.DiscountsMarkups") Then
		CurrentObject.AdditionalFilterIsSet = ValueIsFilled(String(Form.SettingsComposerAdditionalConditions.Settings.Filter));
		DataCompositionSettings.Insert("AdditionalConditions", Form.SettingsComposerAdditionalConditions.GetSettings());
	EndIf;
	
	// Place settings without a cached request.
	// The Data Filter function in the nomenclature reads the settings from the object to prepare a cached request.
	CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(DataCompositionSettings);
	
	InsertCachedQuery(DataCompositionSettings, CurrentObject);
	
	CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(DataCompositionSettings);
	
EndProcedure

// Event handler before Recording.
//
// Parameters:
// 	CurrentObject - CatalogObject.DiscountsMarkups, CatalogObject.DiscountMarkupTerms - 
// 	Cancel - Boolean - True if an error occurred
// 
Procedure BeforeWrite(CurrentObject, Cancel) Export
	
	If CurrentObject.IsFolder Then
		Return;
	EndIf;
	
	DataCompositionSettings = CurrentObject.StorageOfDataCompositionSettings.Get();
	
	If TypeOf(DataCompositionSettings) = Type("Structure") Then
		ExceptionText = "";
		RequestingDataLayoutSettings = Undefined;
		If DataCompositionSettings.Property("Query", RequestingDataLayoutSettings) Then
			If TypeOf(RequestingDataLayoutSettings) = Type("Structure") Then
				QueryTextDataCompositionSettings = Undefined;
				RequestParametersDataLayoutSettings = Undefined;
				If RequestingDataLayoutSettings.Property("QueryText", QueryTextDataCompositionSettings) And 
					 RequestingDataLayoutSettings.Property("Parameters", RequestParametersDataLayoutSettings) Then
					 
					 RequestToCheckParameters = New Query(QueryTextDataCompositionSettings);
					 For Each QueryParameter In RequestToCheckParameters.Parameters Do
						 If Not RequestParametersDataLayoutSettings.Property(QueryParameter.Key) Then
							Cancel = True;
							ExceptionText = NStr("vi = 'Trong mục tin %1 bộ tham số không tương ứng với tham số nội dung truy vấn';
												|ru = 'В реквизите %1 коллекция параметров не соответствует параметрам текста запроса';
												|en = 'Parameter collection in attribute %1 does not match query text parameters'; fa = 'Parameter collection in attribute %1 does not match query text parameters';
												|it = 'Nel requisito %1 la raccolta dei parametri non corrisponde ai parametri del testo della query';
												|pl = 'W atrybucie %1 kolekcja parametrów nie pasuje do parametrów tekstu zapytania';
												|tr = '%1 özniteliğinde parametre koleksiyonu sorgu metninin parametrelerine karşılık gelmiyor'");
							ExceptionText = StrTemplate(ExceptionText, "StorageOfDataCompositionSettings");
							Break;
						 EndIf;
					 EndDo;
					 
				EndIf;
			Else	
				Cancel = True;
				ExceptionText = NStr("vi = 'Trong mục tin %1 không có dữ liệu về truy vấn';
									|ru = 'В реквизите %1 нет данных о запросе';
									|en = 'Attribute %1 does not contain query information'; fa = 'Attribute %1 does not contain query information';
									|it = 'Nel requisito %1 non ci sono i dati sulla query';
									|pl = 'W atrybucie %1 brak danych żądania';
									|tr = '%1 özniteliğinde sorgu ile ilgili veriler yok'");
				ExceptionText = StrTemplate(ExceptionText, "StorageOfDataCompositionSettings");
			EndIf;
		EndIf;
		
		If Cancel Then
			Raise ExceptionText;
		EndIf;	
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - The Form contains, among other things:
// 		* Object - CatalogObject.DiscountsMarkups, CatalogObject.DiscountMarkupTerms - 
// 	CurrentObject - CatalogObject.DiscountsMarkups, CatalogObject.DiscountMarkupTerms - 
// 
Procedure OnCreatReadAtServer(Form, CurrentObject = Undefined) Export
	
	If CurrentObject <> Undefined Then
		Form.AddressOfExternalDataProcessorSettings = PutToTempStorage(CurrentObject.ExternalDataProcessorParameters.Get(), Form.UUID);
		Settings = CurrentObject.StorageOfDataCompositionSettings.Get();
	Else
		If Form.Parameters.Property("CopyingValue") And ValueIsFilled(Form.Parameters.CopyingValue) Then
			CopiedObject = Common.ObjectAttributesValues(Form.Parameters.CopyingValue, "ExternalDataProcessorParameters,StorageOfDataCompositionSettings");
			ExternalDataProcessorParameters = CopiedObject.ExternalDataProcessorParameters; // ValueStorage
			Form.AddressOfExternalDataProcessorSettings = PutToTempStorage(ExternalDataProcessorParameters.Get(), Form.UUID);
			StorageOfDataCompositionSettings = CopiedObject.StorageOfDataCompositionSettings; // ValueStorage
			Settings = StorageOfDataCompositionSettings.Get();
		Else
			Form.AddressOfExternalDataProcessorSettings = PutToTempStorage(Undefined, Form.UUID);
		EndIf;
	EndIf;
	
	If TypeOf(Form.Object.Ref) = Type("CatalogRef.DiscountMarkupTerms") Then
		
		For Each CatalogDetails In Metadata.Catalogs.DiscountMarkupTerms.Attributes Do
			
			FillValue = CatalogDetails.FillValue;
			If TMCommonUseClientServer.HasObjectAttribute(Form.Object, CatalogDetails.Name)
				And Not ValueIsFilled(Form.Object[CatalogDetails.Name]) Then
				Form.Object[CatalogDetails.Name] = FillValue;
			EndIf;
			
			If CatalogDetails = Metadata.Catalogs.DiscountMarkupTerms.Attributes.RestrictionCurrency
				And Not ValueIsFilled(Form.Object.RestrictionCurrency) Then
				Form.Object.RestrictionCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting();
			EndIf;
			
		EndDo;
		
		DiscountsMarkupsClientServer.ProvisionConditionWhenChangedOnServer(Form);
		DiscountsMarkupsClientServer.CriteriaForApplyingForSalesVolumeWhenChangingOnServer(Form);
		DiscountsMarkupsClientServer.OptionForDeterminingCumulativeDiscountPeriodWhenChangingOnServer(Form);
		
		If Not ValueIsFilled(Form.Object.Ref) Then
			Form.Object.Description = DiscountsMarkupsClientServer.AutoNameDiscountConditions(Form);
		Else
			DiscountsMarkupsClientServer.AutoNameDiscountConditions(Form);
		EndIf;
		DiscountsMarkupsClientServer.UpdateAutoNamingDetails(Form);
		
		TermsOfServiceElement = Form.Items.DiscountMarkupCondition; // FormFieldExtensionForATextBox
		
		For Each ListItem In AvailableConditionsForDiscountsMarkups() Do
			TermsOfServiceElement.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
		UseProductSegments = GetFunctionalOption("UseProductSegments");
		ElementsProductSelectionOption = New Array;
		ElementsProductSelectionOption.Add("GroupItemSelectionOptionForAccumulatedSalesVolumeItemSegment");
		ElementsProductSelectionOption.Add("GroupItemSelectionOptionItemSegment");
		For Each TagName In ElementsProductSelectionOption Do
			Form.Items[TagName].Visible = UseProductSegments;
		EndDo;
		
		Form.Items.PaymentMethod.ChoiceList.Clear();
		Form.Items.PaymentMethod.ChoiceList.Add(Enums.PaymentForms.CashAccountPayment_);
		Form.Items.PaymentMethod.ChoiceList.Add(Enums.PaymentForms.BankAccountPayment);
		If GetFunctionalOption("UsePaymentByCards") Then
			Form.Items.PaymentMethod.ChoiceList.Add(Enums.PaymentForms.PaymentCard);
		EndIf;
		If GetFunctionalOption("UseLoyaltyPrograms") Then
			Form.Items.PaymentMethod.ChoiceList.Add(Enums.PaymentForms.BonusPoints);
		EndIf;
		If GetFunctionalOption("UseGiftCards") Then
			Form.Items.PaymentMethod.ChoiceList.Add(Enums.PaymentForms.GiftCertificate);
		EndIf;
		
	
	EndIf;
	
	If TypeOf(Form.Object.Ref) = Type("CatalogRef.DiscountsMarkups") Then
		
		Form.Items.ItemFilterOption.ChoiceList.Clear();
		Form.Items.ItemFilterOption.ChoiceList.Add(
			Enums.ItemFilterOptionsForDiscountMarkupCalculation.WithoutRestrictions,
			NStr("vi = 'Mặt hàng bất kỳ';
				|ru = 'Любую номенклатуру';
				|en = 'Any items'; fa = 'هر قلم';
				|it = 'Qualsiasi articolo';
				|pl = 'Jakikolwiek produkt';
				|tr = 'Herhangi bir öğeyi'"));
		Form.Items.ItemFilterOption.ChoiceList.Add(
			Enums.ItemFilterOptionsForDiscountMarkupCalculation.ItemList,
			NStr("vi = 'Mặt hàng từ danh sách';
				|ru = 'Номенклатуру из списка';
				|en = 'Items from the list'; fa = 'Items from the list';
				|it = 'Articoli dall''elenco';
				|pl = 'Produkt z listy';
				|tr = 'Listeden öğe'"));
		If GetFunctionalOption("UseProductSegments") Then
			Form.Items.ItemFilterOption.ChoiceList.Add(
				Enums.ItemFilterOptionsForDiscountMarkupCalculation.ProductSegment,
				NStr("vi = 'Mặt hàng thuộc phân khúc';
					|ru = 'Номенклатуру из сегмента';
					|en = 'Items from segment'; fa = 'اقلام از بخش';
					|it = 'Articoli dal segmento';
					|pl = 'Produkt z segmentu';
					|tr = 'Segmentteki öğeyi'"));
			Form.Items.ItemFilterOption.ChoiceList.Add(
				Enums.ItemFilterOptionsForDiscountMarkupCalculation.NotProductSegment,
				NStr("vi = 'Mặt hàng không thuộc phân khúc';
					|ru = 'Номенклатуру не из сегмента';
					|en = 'Items not from segment'; fa = 'اقلام خارج از بخش';
					|it = 'Nomenclatura non appartenente al segmento';
					|pl = 'Pozycje nie z segmentu';
					|tr = 'Segmentte olmayan öğeyi'"));
		EndIf;
		Form.Items.ItemFilterOption.ChoiceList.Add(
			Enums.ItemFilterOptionsForDiscountMarkupCalculation.DataCompositionFilter,
			NStr("vi = 'Mặt hàng theo bộ lọc';
				|ru = 'Номенклатуру по отбору';
				|en = 'Items by filter'; fa = 'اقلام بر اساس فیلتر';
				|it = 'Articoli secondo la selezione';
				|pl = 'Produkt wg wyboru';
				|tr = 'Filtre kapsamındaki öğeyi'"));
		
	EndIf;
	
	If TypeOf(Form.Object.Ref) = Type("CatalogRef.DiscountsMarkups") Then
		DataCompositionSchema = Catalogs.DiscountsMarkups.GetTemplate("RowsFilterItems");
	Else
		DataCompositionSchema = Catalogs.DiscountsMarkups.GetTemplate("FilterTermsAmountQuantity");
	EndIf;

	Form.SettingsComposerFilterByProducts.Initialize(
		New DataCompositionAvailableSettingsSource(
			PutToTempStorage(DataCompositionSchema, Form.UUID)));
	If ValueIsFilled(Settings) And TypeOf(Settings) = Type("Structure") And Settings.Property("FilterRemainingGoodsByShelfLives") Then
		Form.SettingsComposerFilterByProducts.LoadSettings(Settings.FilterRemainingGoodsByShelfLives);
	Else
		Form.SettingsComposerFilterByProducts.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	Form.SettingsComposerFilterByProducts.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	If TypeOf(Form.Object.Ref) = Type("CatalogRef.DiscountsMarkups") Then
		
		DataCompositionSchema = Catalogs.DiscountsMarkups.GetTemplate("RowsFilterAdditionalConditions");
		Form.SettingsComposerAdditionalConditions.Initialize(
			New DataCompositionAvailableSettingsSource(
				PutToTempStorage(DataCompositionSchema, Form.UUID)));
		If ValueIsFilled(Settings) And TypeOf(Settings) = Type("Structure") And Settings.Property("AdditionalConditions") Then
			Form.SettingsComposerAdditionalConditions.LoadSettings(Settings.AdditionalConditions);
		Else
			Form.SettingsComposerAdditionalConditions.LoadSettings(DataCompositionSchema.DefaultSettings);
		EndIf;
		Form.SettingsComposerAdditionalConditions.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
		
	EndIf;
	
	DiscountsMarkupsClientServer.ConfigureHyperlinkToListOfItems(Form);
	
	DiscountsMarkupsClientServer.ConfigureSelectionHyperlinks(Form);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - The Form contains, among other things:
// 		* TermsCommands - ValueTable - The table contains:
// 			** CommandName - String - 
// 			** Value - Arbitrary - 
// 	GroupCreate - FormGroup 
// 
Procedure AddCommandsToCreateNewConditionsForDiscountsMarkups(Form, GroupCreate) Export
	
	FormCommands = AvailableConditionsForDiscountsMarkups();
	
	For Each ListItem In FormCommands Do
		
		CommandName = "AttachableCommand" + StrReplace(New UUID, "-","");
		
		NewRow = Form.TermsCommands.Add();
		NewRow.CommandName = CommandName;
		NewRow.Value = ListItem.Value;
		
		FormCommand = Form.Commands.Add(CommandName);
		FormCommand.Action = "Attachable_ExecuteCommandToCreateConditionsForProvisionOfDiscountsMargins";
		FormCommand.Title = ListItem.Presentation;
		FormCommand.ModifiesStoredData = False;
		FormCommand.Representation = ButtonRepresentation.Auto;
		
		NewItem = Form.Items.Add("Button"+CommandName, Type("FormButton"), GroupCreate);
		NewItem.Type = FormButtonType.CommandBarButton;
		NewItem.CommandName = CommandName;
		
	EndDo;
	
EndProcedure

Procedure AddCommandsToCreateNewDiscountsMarkups(Form, GroupCreate) Export
	
	Variants = AvailableDeliveryMethods();
	
	For Each ListItem In Variants.DiscountsMarkups Do
		AddTeamToGroup(ListItem, Form, GroupCreate, "DiscountsMarkups");
	EndDo;
	
	If GetFunctionalOption("UseLoyaltyPrograms") Then
		For Each ListItem In Variants.BonusPoints Do
			AddTeamToGroup(ListItem, Form, GroupCreate, "BonusPoints");
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region QueryPackageFunctions

// Request package constructor.
//
// Returns:
//	Structure - request package. Consists of:
//		* TotalNumberOfTables - Number
//		* MatchingQueryAndResultTableNumber - Map
//		* Query - Query
//		* Parameters - Map
//		* QueryResult - QueryResult
//		* ArrayOfQueryNames - Array
//
Function CreateRequestPackage()
	
	QueryBatch = New Structure;
	QueryBatch.Insert("TotalNumberOfTables", 0);
	QueryBatch.Insert("MatchingQueryAndResultTableNumber", New Map);
	QueryBatch.Insert("Query", New Query);
	QueryBatch.Insert("Parameters", New Map);
	QueryBatch.Insert("QueryResult", Undefined);
	QueryBatch.Insert("ArrayOfQueryNames", New Array);
	
	Return QueryBatch;
	
EndFunction

Procedure DeleteTemporaryTables(Query)
	
	SetPrivilegedMode(True);
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(Query.Text);
	TablesToDestroy = New Array;
	For IndexOf = 0 To QuerySchema.QueryBatch.Count() - 1 Do
		SchemaRequest = QuerySchema.QueryBatch.Get(IndexOf);
		If TypeOf(SchemaRequest) = Type("QuerySchemaSelectQuery") Then
			If ValueIsFilled(SchemaRequest.PlacementTable) Then
				TablesToDestroy.Add(SchemaRequest.PlacementTable);
			EndIf;
		ElsIf TypeOf(SchemaRequest) = Type("QuerySchemaTableDropQuery") Then
			IndexOf = TablesToDestroy.Find(SchemaRequest.TableName);
			If IndexOf <> Undefined Then
				TablesToDestroy.Delete(IndexOf);
			EndIf;
		EndIf;
	EndDo;
	For Each TableName In TablesToDestroy Do
		Query.Text = Query.Text + StrReplace(
			Common.QueryBatchSeparator() + "DROP TableName", "TableName", TableName) + Chars.LF;
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Adds a request to the request package.
//
Procedure RequestPackageInsertRequestIntoPackage(Query,
	                                        QueryBatch,
	                                        Var_Key,
	                                        DeleteTemporaryTables_,
	                                        TransformParameters,
	                                        NumberOfRequestsPerBatch = Undefined,
	                                        ResultQueryIndex = Undefined)
	
	// Checking for duplicate requests.
	If Var_Key <> Undefined
		And QueryBatch.ArrayOfQueryNames.Find(Var_Key) <> Undefined Then
		Return;
	EndIf;
	
	If TransformParameters Then
		For Each Parameter In Query.Parameters Do
			NewName = RequestPackageConvertParameter(Query.Text, Parameter.Key, Parameter.Value, QueryBatch);
			If NewName <> Undefined Then
				QueryBatch.Query.SetParameter(NewName, Parameter.Value);
				QueryBatch.Parameters.Insert(Parameter.Value, NewName);
			EndIf;
		EndDo;
	EndIf;
	
	If DeleteTemporaryTables_ Then
		DeleteTemporaryTables(Query);
	EndIf;
	
	If NumberOfRequestsPerBatch = Undefined Or ResultQueryIndex = Undefined Then
		If StrOccurrenceCount(Query.Text, ";") > 0 Then
			Subqueries = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Query.Text, ";");
			NumberOfRequestsPerBatch = Subqueries.Count();
			ResultQueryIndex = 0;
			For IndexOf = -(NumberOfRequestsPerBatch - 1) To 0 Do
				If Find(Subqueries[-IndexOf], "#123456789#") > 0 Then
					ResultQueryIndex = -IndexOf + 1;
				EndIf;
			EndDo;
		Else
			NumberOfRequestsPerBatch = 1;
			ResultQueryIndex = 1;
		EndIf;
	EndIf;
	
	QueryBatch.TotalNumberOfTables = QueryBatch.TotalNumberOfTables + NumberOfRequestsPerBatch;
	
	If QueryBatch.TotalNumberOfTables = NumberOfRequestsPerBatch Then
		QueryBatch.Query.Text = Query.Text;
	Else
		QueryBatch.Query.Text = QueryBatch.Query.Text + Common.QueryBatchSeparator() + Query.Text;
	EndIf;
	
	If Var_Key <> Undefined Then
		TableNumber = QueryBatch.TotalNumberOfTables - NumberOfRequestsPerBatch + ResultQueryIndex;
		QueryBatch.MatchingQueryAndResultTableNumber.Insert(Var_Key, TableNumber);
		QueryBatch.ArrayOfQueryNames.Add(Var_Key);
	EndIf;
	
EndProcedure

// Executes a batch of requests.
//
// Returns:
//	Boolean - True if the request is successful.
//
Function QueryBatchExecute(QueryBatch)
	
	If ValueIsFilled(QueryBatch.Query.Text) Then
		QueryBatch.QueryResult = QueryBatch.Query.ExecuteBatch();
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Gets the result of a query by name from the query package.
//
// Returns:
//	QueryResult - The result of the request included in the package.
//
Function BatchQueriesResultByName(QueryName1, QueryBatch)
	
	Return QueryBatch.QueryResult[QueryBatch.MatchingQueryAndResultTableNumber[QueryName1] - 1];
	
EndFunction

Function RequestPackagePostfixes()
	
	Postfixes = New Array;
	Postfixes.Add(Chars.LF);
	Postfixes.Add(" ");
	Postfixes.Add(",");
	Postfixes.Add(".");
	Postfixes.Add(")");
	Postfixes.Add(Chars.Tab);
	Postfixes.Add("(");
	Postfixes.Add("+");
	Postfixes.Add("-");
	Postfixes.Add("*");
	Postfixes.Add("/");
	
	Return Postfixes;
	
EndFunction

Function ReplaceParameterNameInRequest(QueryText, OriginalName, NewName, Postfixes)
	
	For Each Postfix In Postfixes Do
		QueryText = StrReplace(QueryText, "&" + OriginalName + Postfix, "&" + NewName + Postfix);
	EndDo;

EndFunction

// Converts the request parameter (Changes the name or eliminates the need to use the parameter).
// Used for combining queries with the same parameters.
//
// Parameters:
// 	QueryText - String - 
// 	OriginalName - String - 
// 	ParameterValue - EnumRef - 
// 	QueryBatch - QuerySchemaQueryBatch -
// 	 
// Returns:
//	String - The new name of the parameter.
//
Function RequestPackageConvertParameter(QueryText, OriginalName, ParameterValue, QueryBatch = Undefined)
	
	Postfixes = RequestPackagePostfixes();
	
	TypeOf = TypeOf(ParameterValue);
	
	NewName = Undefined;
	
	If TypeOf = Type("Date") Then
		Text = "DateTime("+Format(Year(ParameterValue),"NZ=0; NG=0")+","+Month(ParameterValue)+","+Day(ParameterValue)+","+Hour(ParameterValue)+","+Minute(ParameterValue)+","+Second(ParameterValue)+")";
		For Each Postfix In Postfixes Do
			QueryText = StrReplace(QueryText, "&" + OriginalName + Postfix, Text + Postfix);
		EndDo;
	ElsIf TypeOf = Type("Number") Then
		Text = Format(ParameterValue, "NDS=.; NZ=; NG=0");
		For Each Postfix In Postfixes Do
			QueryText = StrReplace(QueryText, "&" + OriginalName + Postfix, Text + Postfix);
		EndDo;
	ElsIf TypeOf = Type("Boolean") Then
		Text = ?(ParameterValue, "TRUE", "FALSE");
		For Each Postfix In Postfixes Do
			QueryText = StrReplace(QueryText, "&" + OriginalName + Postfix, Text + Postfix);
		EndDo;
	ElsIf ParameterValue = "" Then
		For Each Postfix In Postfixes Do
			QueryText = StrReplace(QueryText, "&" + OriginalName + Postfix, Postfix);
		EndDo;
	ElsIf ValueIsFilled(ParameterValue) And Enums.AllRefsType().ContainsType(TypeOf) Then
		
		ParameterMetadata = ParameterValue.Metadata(); // MetadataObject
		EnumerationName = ParameterMetadata.Name;
		EnumValueName = Metadata.Enums[EnumerationName].EnumValues[Enums[EnumerationName].IndexOf(ParameterValue)].Name;
		
		Text = "VALUE(Enum." + EnumerationName + "." + EnumValueName + ")";
		For Each Postfix In Postfixes Do
			QueryText = StrReplace(QueryText, "&" + OriginalName + Postfix, Text + Postfix);
		EndDo;
		
	Else
		
		If QueryBatch <> Undefined Then
			Var_Key = QueryBatch.Parameters.Get(ParameterValue);
		EndIf;
		If Var_Key = Undefined Then
			
			If QueryBatch <> Undefined And QueryBatch.Query.Parameters.Property(OriginalName) Then
			
				NewName = "P" + StrReplace(New UUID,"-","_");
				ReplaceParameterNameInRequest(QueryText, OriginalName, NewName, Postfixes);
				
			Else
				
				NewName = OriginalName;
				
			EndIf;
			
		Else
			
			ReplaceParameterNameInRequest(QueryText, OriginalName, Var_Key, Postfixes);
			
		EndIf;
		
	EndIf;
	
	Return NewName;
	
EndFunction

#EndRegion

#Region Other

// Returns an empty table of values for storing the result of calculated discounts (markups).
//
// Returns:
//	ValueTable - The table contains:
//		* ConnectionKey   - Number
//		* Details - ValueTable
//		* Sum       - Number
//		* Valid   - Boolean
//
Function EmptyDiscountTableWithDecryption(CalculationParameters = Undefined) Export
	
	If CalculationParameters = Undefined Then
		Table = New ValueTable;
		Table.Columns.Add("ConnectionKey",   New TypeDescription("Number"));
		Table.Columns.Add("Details", New TypeDescription("ValueTable"));
		Table.Columns.Add("Sum",       New TypeDescription("Number"));
		Table.Columns.Add("Valid",   New TypeDescription("Boolean"));
		Return Table;
	Else
		Return CalculationParameters.EmptyDiscountTableWithDecryption.CopyColumns();
	EndIf;
	
EndFunction

// Returns an empty table of values for storing transcripts.
// 
// Returns:
// 	ValueTable - The table contains:
// * DiscountMarkup - CatalogRef.DiscountsMarkups
// * Sum - Number
// * ThisIsMessage - Boolean
// 
Function EmptyDecryptionTable(CalculationParameters = Undefined)
	
	If CalculationParameters = Undefined Then
		Table = New ValueTable;
		Table.Columns.Add("DiscountMarkup", New TypeDescription("CatalogRef.DiscountsMarkups"));
		Table.Columns.Add("Sum",         New TypeDescription("Number"));
		Table.Columns.Add("ThisIsMessage",  New TypeDescription("Boolean"));
		Return Table;
	Else
		Return CalculationParameters.EmptyDecryptionTable.CopyColumns();
	EndIf;
	
EndFunction

// Returns an empty table of values for storing transcripts.
// 
// Returns:
// 	ValueTable - The table contains:
// * ConnectionKey - Number
// * DiscountMarkup - CatalogRef.DiscountsMarkups
// * Sum - Number
//
Function EmptyDiscountMarkUpTable(CalculationParameters = Undefined)
	
	If CalculationParameters = Undefined Then
		Table = New ValueTable;
		Table.Columns.Add("ConnectionKey",     New TypeDescription("Number"));
		Table.Columns.Add("DiscountMarkup", New TypeDescription("CatalogRef.DiscountsMarkups"));
		Table.Columns.Add("Sum",         New TypeDescription("Number"));
		Return Table;
	Else
		Return CalculationParameters.EmptyDiscountMarkUpTable.CopyColumns();
	EndIf;
	
EndFunction

// Returns an empty table of values for the results of checking conditions.
// 
// Returns:
// 	ValueTable - The table contains:
// * Ref - CatalogRef.DiscountMarkupTerms, CatalogRef.DiscountsMarkups -
// * ConnectionKey - Number
// * MultiplicityOfExecution - Number
// * IndicatorValue - 
// 
Function EmptyTableConditionValidationResult()
	
	VT = New ValueTable;
	VT.Columns.Add("Ref",              New TypeDescription("CatalogRef.DiscountMarkupTerms,CatalogRef.DiscountsMarkups"));
	VT.Columns.Add("ConnectionKey",           New TypeDescription("Number"));
	VT.Columns.Add("MultiplicityOfExecution", New TypeDescription("Number"));
	VT.Columns.Add("IndicatorValue");
	
	Return VT;
	
EndFunction

// Returns an empty refinement table for discounts/markups.
// 
// Returns:
// 	ValueTable - The table contains:
// * Key - Number - 
// * Value - Number -
// 
Function EmptyTableForSpecifyingDiscountMarkUpValue()
	
	VT = New ValueTable;
	VT.Columns.Add("Key");
	VT.Columns.Add("Value", New TypeDescription("Number"));
	
	Return VT;
	
EndFunction


Function RemoveExtraRowsOfDiscountTreeRecursively(DiscountTree)
	
	For Each TreeRow In DiscountTree.Rows Do
		
		If TreeRow.IsFolder Then
			
			RemoveExtraRowsOfDiscountTreeRecursively(TreeRow);
			
		Else
			
			If TreeRow.Rows.Count() > 0 Then
				FillPropertyValues(TreeRow, TreeRow.Rows[0]);
				TreeRow.Rows.Delete(TreeRow.Rows[0]);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndFunction

// Creates a tree of discounts/markups
// 
// Returns:
// 	ValueTree - Contains:
// 		* Ref - CatalogRef.DiscountsMarkups
// 		* AddlOrderingAttribute - Number - The order of application
// 		* JointApplicationOption - EnumRef.OptionsOfJointUsageOfDiscountsAndMarkups - The option of joint application
// 		* OptionOfJointApplicationResultCalculation - EnumRef.OptionsOfJointApplicationResultCalculation
// 			Option for calculating the result of joint application
// 		* DeletionMark - Boolean - Mark to delete an item
// 		* MethodsOfProviding - CatalogRef.AdditionalReportsAndDataProcessors, EnumRef.MethodsToProvideDiscountsMarkups - 
// 			Defines the method by which the discount (mark-up) is granted)
// 		* DiscountApplicationMethod - EnumRef.DiscountMarkupApplicationMethods - How to apply the discount
// 		* ApplyMultiplicationWithinParentGroup - Boolean - Apply multiplication within the parent group
// 		* DiscountMarkupValue - DefinedType.MonetaryAmountPositiveNegative - The value of the discount margin
// 		* RoundingPrecision - DefinedType.MonetaryAmountNonNegative - Rounding accuracy
// 		* RoundOffOption - EnumRef.RoundingOptions - The option of rounding
// 		* SmartRounding - DefinedType.MonetaryAmountNonNegative - Psychological rounding
// 		* IsFolder - Boolean
// 		* Managed - Boolean - Is manually assigned
// 		* AssignedByUser - Boolean - Assigned by the user
// 		* PriceKind - CatalogRef.TypesOfPrices - Type of price
// 		* GiftSegment - CatalogRef.ProductSegments - A segment of gifts
// 		* ProductSegmentRestrictions - CatalogRef.ProductSegments - Item segment restrictions
// 		* UseMultiplier - Boolean - To use multiplicity
// 		* DiscountConditionByQuantity - Number - Condition for quantity discount
// 		* ItemFilterOption - EnumRef.ItemFilterOptionsForDiscountMarkupCalculation
// 			Item selection option
// 		* ExternalDataProcessorParameters - ValueStorage - External processing parameters
// 		* AdditionalFilterIsSet - Boolean - Additional selection is set
// 		* StorageOfDataCompositionSettings - ValueStorage - Storage of data layout settings
// 		* ApplyVariants - Boolean - Take into account the characteristics
// 		* BonusConversionCurrency - CatalogRef.Currencies - Bonus conversion currency
// 		* ConversionRateOfBonusesIntoCurrency - Number - The conversion rate of bonuses in the currency
// 		* DiscountMarkupCurrency - CatalogRef.Currencies - Grant currency
// 		* DiscountMarkupConditions - ValueTable
// 		* CalculationResult2 - See EmptyDiscountTableWithDecryption
// 		* ConditionParameters_ - Structure - contains including:
// 			** ConditionsAreFulfilled - Boolean
// 			** LineCodes - Array
// 			** ConditionsByLine - Structure - contains including:
// 				*** ConditionVerificationTable - ValueTable
// 				*** MatchingConditionsToColumnsInConditionVerificationTable - Map
// 			** ThereAreConditionsOnLine - Boolean
// 			** TableOfConditions - ValueTable
// 
Function CreateDiscountTree(Data)
	
	If TypeOf(Data) = Type("Structure") Then
		
		DiscountTree = BatchQueriesResultByName("DiscountsMarkups", Data).Unload(QueryResultIteration.ByGroupsWithHierarchy);
		
	Else
		
		CalculationParameters = New Structure;
		CalculationParameters.Insert("DiscountsMarkups", Data);
		CalculationParameters.Insert("ManagedDiscounts", New Array);
		
		Query = RequestDiscountMarkUp(CalculationParameters, False);
		
		DiscountTree = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
		
	EndIf;
	
	RemoveExtraRowsOfDiscountTreeRecursively(DiscountTree);
	
	Return DiscountTree;
	
EndFunction

// Returns:
// 	Structure - Contains:
// * Object - Undefined
// * User - CatalogRef.Users
// * ManagementAccountingCurrency - CatalogRef.Currencies
// * DocumentCurrency - CatalogRef.Currencies
// * Goods - Array, ValueTable -
// * LoyaltyCard - CatalogRef.LoyaltyCards
// * PaymentSchedule - CatalogRef.PaymentSchedules
// * CurrentDate - Date
// * CurrentTime - Date
// * WeekDay - EnumRef.WeekDays
// * PaymentMethod - EnumRef.PaymentForms
// * Recorder - DocumentRef.CustomerInvoice
// * Terms - CatalogRef.TermsOfSale
// * Partner - CatalogRef.Partners
// * DiscountsMarkups - Array of CatalogRef.DiscountsMarkups
// 
Function CalculationParameters() Export
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("DiscountsMarkups", New Array);
	CalculationParameters.Insert("Partner", Catalogs.Partners.EmptyRef());
	CalculationParameters.Insert("Terms", Catalogs.TermsOfSale.EmptyRef());
	CalculationParameters.Insert("Recorder", Documents.CustomerInvoice.EmptyRef());
	CalculationParameters.Insert("BaseCurrency", Catalogs.Currencies.EmptyRef());
	
	// For the discount "For the form of payment".
	CalculationParameters.Insert("PaymentMethod", Enums.PaymentForms.EmptyRef());
	
	// For a discount "For the time of sale".
	CalculationParameters.Insert("WeekDay", Enums.WeekDays.EmptyRef());
	CalculationParameters.Insert("CurrentTime", '00010101');
	CalculationParameters.Insert("CurrentDate", '00010101');
	
	// For the discount "For compliance with the payment schedule".
	CalculationParameters.Insert("PaymentSchedule", Catalogs.PaymentSchedules.EmptyRef());
	
	// Loyalty card
	CalculationParameters.Insert("LoyaltyCard", Catalogs.LoyaltyCards.EmptyRef());
	
	CalculationParameters.Insert("Goods", New Array);
	CalculationParameters.Insert("DocumentCurrency", Catalogs.Currencies.EmptyRef());
	CalculationParameters.Insert("ManagementAccountingCurrency", Catalogs.Currencies.EmptyRef());
	CalculationParameters.Insert("User", Catalogs.Users.EmptyRef());
	CalculationParameters.Insert("Object", Undefined);
	
	Return CalculationParameters;
	
EndFunction

Function BeginningOfDecade(Date)
	
	If Day(Date) < 11 Then
		
		Return BegOfMonth(Date);
		
	ElsIf Day(Date) < 21 Then
		
		Return BegOfMonth(Date) + 86400 * 10;
		
	Else
		
		Return BegOfMonth(Date) + 86400 * 20;
		
	EndIf;
	
EndFunction

Function BeginningOfHalfYear(Date)
	
	If Month(Date) < 6 Then
		Return BegOfYear(Date)
	Else
		Return TMCommonUseClientServer.CalculatePeriodEndDate(
			BegOfYear(Date),
			Enums.Periodicity.HalfYear,
			1) + 1;
	EndIf;
	
EndFunction

// Parameters:
// 	Form - ClientApplicationForm - The Form contains, among other things:
// 		* TermsCommands - ValueTable - The table contains:
// 			** CommandName - String - 
// 			** Value - Arbitrary -
// 
Procedure AddTeamToGroup(ListItem, Form, GroupCreate, Var_Key)
	
	CommandName = "AttachableCommand" + Var_Key + (GroupCreate.ChildItems.Count() + 1);
	
	NewRow = Form.TermsCommands.Add();
	NewRow.CommandName = CommandName;
	NewRow.Value = ListItem.Value;
	
	FormCommand = Form.Commands.Add(CommandName);
	FormCommand.Action = "Attachable_ExecuteCommandToAddDiscountMarkUp";
	FormCommand.Title = ListItem.Presentation;
	FormCommand.ModifiesStoredData = False;
	FormCommand.Representation = ButtonRepresentation.Auto;
	
	NewItem = Form.Items.Add("Button"+CommandName, Type("FormButton"), GroupCreate);
	NewItem.Type = FormButtonType.CommandBarButton;
	NewItem.CommandName = CommandName;
	
EndProcedure

Function TemporaryTableNameAccumulatedSales(DiscountMarkupCondition, Interval)
	
	If DiscountMarkupCondition.AccumulationOption = Enums.OptionsOfCumulativeDiscountMarkupAccumulation.ByPartner Then
		TempTableName = "AccumulatedPartnerSalesForPeriod";
	ElsIf DiscountMarkupCondition.AccumulationOption = Enums.OptionsOfCumulativeDiscountMarkupAccumulation.ByTermsOfSales Then
		TempTableName = "AccumulatedSalesUnderTradeAgreementForPeriod";
	EndIf;
	
	PresentationStartDate    = Format(Interval.StartDate, "DF=ddMMyyyy; DE=");
	If IsBlankString(PresentationStartDate) Then
		PresentationStartDate = "01010001";
	EndIf;
	PresentationEndDate = Format(Interval.EndDate, "DF=ddMMyyyy; DE=");
	If IsBlankString(PresentationEndDate) Then
		PresentationEndDate = "01010001";
	EndIf;
	
	TempTableName = TempTableName
	                    + PresentationStartDate
	                    + PresentationEndDate
	                    + TrimAll(DiscountMarkupCondition.DigitalCurrencyCodeRestrictions)
	                    + ?(DiscountMarkupCondition.IncludeCurrentSaleInAccumulatedSalesVolume, "IncludingCurSale", "ExcludingCurSale");
	
	Return TempTableName;
	
EndFunction

#EndRegion

#EndRegion
