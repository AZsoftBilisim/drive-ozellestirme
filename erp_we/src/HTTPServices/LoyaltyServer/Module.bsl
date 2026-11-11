#Region EventHandlers

Function pingGET(Query)
	
	Response = New HTTPServiceResponse(200);
	ResponseStructure = Undefined;
	LoyaltyService.GetParametersOfConnectionVerificationResponse(ResponseStructure);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	If UseLoyaltyServer Then
		
		ResponseStructure.Connection = True;
		
	Else
		
		ResponseStructure.Error = True;
		ResponseStructure.ErrorMessage = NStr("vi = 'Đã ngắt sử dụng máy chủ khách hàng thân thiết trong các tùy chỉnh chương trình.';
												|ru = 'Использование сервера лояльности отключено в настройках программы.';
												|en = 'Loyalty server is disabled in the application settings.'; fa = 'Loyalty server is disabled in the application settings.';
												|it = 'Использование сервера лояльности отключено в настройках программы.';
												|pl = 'Loyalty server is disabled in the application settings.';
												|tr = 'Sadakat sunucusunun kullanımı program ayarlarında devre dışı bırakıldı.'");
		
	EndIf;
	
	StructureOfJSONResponse = New JSONWriter;
	StructureOfJSONResponse.SetString();
	WriteJSON(StructureOfJSONResponse, ResponseStructure);
	
	Response.SetBodyFromString(StructureOfJSONResponse.Close());
	
	Return Response;
	
EndFunction

Function GetCustomerBonusPointsGET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetResponseParametersClientBonuses(ResponseStructure);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	If Not UseLoyaltyServer Then
		
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		
		Return Response;
		
	EndIf;
	
	Try
		
		MethodParameters = Undefined;
		CustomerCard 	= Undefined;
		
		LoyaltyService.ClientCardDataParameters(Query, MethodParameters);
		
		LoyaltyServiceOverridable.FindCustomerCard(MethodParameters, CustomerCard);
		
		If CustomerCard <> Undefined Then
			
			ResponseStructure.ClientNotFound = False;
			BonusesAreBlocked = LoyaltyService.BonusesAreBlocked(CustomerCard);
			
			If MethodParameters.BonusBlockingIsRequired
				And Not BonusesAreBlocked Then
				LoyaltyServiceOverridable.FillInBonusDetails(CustomerCard, ResponseStructure);
				If ResponseStructure.BonusCount > 0 Then
					LoyaltyService.BlockBonuses(CustomerCard, CurrentSessionDate());
				EndIf;
			EndIf;
			
			LoyaltyServiceOverridable.FillInResponseStructureWithCardNumbers(CustomerCard, ResponseStructure);
			
		EndIf;
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());

		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "GetCustomerBonusPoints");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function UnlockCustomerBonusPointsPOST(Query)
	
	Response = New HTTPServiceResponse(200);
	
	Try
		
		UseLoyaltyServer = False;
		LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
		If Not UseLoyaltyServer Then
			Return Response;
		EndIf;
		
		MethodParameters = Undefined;
		CustomerCard 	= Undefined;
		LoyaltyService.ClientCardDataParameters(Query, MethodParameters);
		LoyaltyServiceOverridable.FindCustomerCard(MethodParameters, CustomerCard);
		
		If CustomerCard <> Undefined Then
			LoyaltyService.UnlockBonuses(CustomerCard);
			MessageText = NStr("vi = 'Đã bỏ chặn điểm thưởng';
								|ru = 'Бонусы разблокированы';
								|en = 'Bonus points are unlocked'; fa = 'Bonus points are unlocked';
								|it = 'Бонусы разблокированы';
								|pl = 'Bonus points are unlocked';
								|tr = 'Bonusların kilidi açıldı'");
		Else
			MessageText = NStr("vi = 'Không tìm thấy thẻ khách hàng';
								|ru = 'Карта клиента не найдена';
								|en = 'Customer card is not found'; fa = 'Customer card is not found';
								|it = 'Карта клиента не найдена';
								|pl = 'Customer card is not found';
								|tr = 'Müşteri kartı bulunmadı'");
		EndIf;
		
		Response.SetBodyFromString(MessageText);
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "UnlockCustomerBonusPoints");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function WriteOffCustomerBonusPointsPOST(Query)
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	If Not UseLoyaltyServer Then
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters = Undefined;
		CustomerCard 	= Undefined;
		LoyaltyService.ClientCardDataParameters(Query, MethodParameters);
		LoyaltyService.AddBonusMethodParameters(Query, MethodParameters);
		LoyaltyServiceOverridable.FindCustomerCard(MethodParameters, CustomerCard);
		
		If CustomerCard <> Undefined Then 
			If ValueIsFilled(MethodParameters.NumberOfBonusPoints) Then
				LoyaltyService.WriteOffAddBonuses(CustomerCard, MethodParameters.NumberOfBonusPoints, 0);
				MessageText = NStr("vi = 'Đã ghi giảm thành công điểm thưởng';
									|ru = 'Бонусы успешно списаны';
									|en = 'Bonus points are written off'; fa = 'Bonus points are written off';
									|it = 'Бонусы успешно списаны';
									|pl = 'Bonus points are written off';
									|tr = 'Bonuslar başarıyla kayıttan düşüldü'");
			Else
				MessageText = NStr("vi = 'Chưa chỉ định số lượng điểm thưởng';
									|ru = 'Количество баллов не указано';
									|en = 'Number of bonus points is not specified'; fa = 'Number of bonus points is not specified';
									|it = 'Количество баллов не указано';
									|pl = 'Number of bonus points is not specified';
									|tr = 'Puan miktarı belirtilmedi'");
			EndIf;
		Else 
			MessageText = NStr("vi = 'Không tìm thấy thẻ khách hàng';
								|ru = 'Карта клиента не найдена';
								|en = 'Customer card is not found'; fa = 'Customer card is not found';
								|it = 'Карта клиента не найдена';
								|pl = 'Customer card is not found';
								|tr = 'Müşteri kartı bulunmadı'");
		EndIf;
		
		Response.SetBodyFromString(MessageText);
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage,
			"WriteOffCustomerBonusPoints");
		
	EndTry;
	
	Return Response;
EndFunction

Function IssueCardToCustomerPOST(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetResponseParametersOfClientSCard(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters = Undefined;
		CustomerCard 	= Undefined;
		LoyaltyService.ClientCardDataParameters(Query, MethodParameters);
		LoyaltyService.AddParametersToIssueCardMethod(Query, MethodParameters);
		LoyaltyServiceOverridable.CheckClientSCardDetails(MethodParameters, ResponseStructure);
		
		If ResponseStructure.Error = False Then
			
			LoyaltyServiceOverridable.FindCustomerCard(MethodParameters, CustomerCard);
			MapExists = ValueIsFilled(CustomerCard);
			OtherClient = Undefined;
			
			If Not MapExists Then
				CustomerCard = Undefined;
				ErrorDescription = "";
				LoyaltyServiceOverridable.CreateCustomerCard(MethodParameters, CustomerCard, OtherClient, ErrorDescription);
			EndIf;

			If ValueIsFilled(CustomerCard) Then
				LoyaltyServiceOverridable.FillInResponseStructureWithMapData(CustomerCard, ResponseStructure, MapExists);
			ElsIf ValueIsFilled(OtherClient) Then
				LoyaltyServiceOverridable.FillInResponseStructureWithClientData(OtherClient, ResponseStructure);
			Else
				ResponseStructure.Error = True;
				If IsBlankString(ErrorDescription) Then
					ResponseStructure.ErrorMessage = NStr("vi = 'Không thể tạo thẻ khách hàng';
															|ru = 'Не удалось создать карту клиента';
															|en = 'Cannot create a customer card'; fa = 'Cannot create a customer card';
															|it = 'Не удалось создать карту клиента';
															|pl = 'Cannot create a customer card';
															|tr = 'Müşteri kartı oluşturulamadı'");
				Else
					ResponseStructure.ErrorMessage = ErrorDescription;
				EndIf;
			EndIf;
			
		EndIf;
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "IssueCardToCustomer");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function InformationOnSalesRestrictionGET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetResponseParametersInformationAboutSalesBans(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	MethodParameters = Undefined;
	LoyaltyService.ParametersOfSalesBansMethod(Query, MethodParameters);
	
	Try
		
		ResponseStructure = Undefined;
		LoyaltyServiceOverridable.DataOnSalesBans(MethodParameters, ResponseStructure);
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "InformationOnSalesRestriction");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function GetGiftCertificateDetailsGET(Query)
	
	Try
		
		Response = New HTTPServiceResponse(200);
		
		UseLoyaltyServer = False;
		LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
		
		ResponseStructure 	= Undefined;
		LoyaltyService.GetResponseParametersGiftCardData(ResponseStructure);
		
		If Not UseLoyaltyServer Then
			LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
			Return Response;
		EndIf;
		
		MethodParameters 	= Undefined;
		CertificateData 	= Undefined;
		LoyaltyService.GiftCardParameters(Query, MethodParameters);
	
		LoyaltyServiceOverridable.FindGiftCard(MethodParameters, CertificateData);
		
		If CertificateData.GiftCertificate <> Undefined Then
			
			LoyaltyServiceOverridable.GetGiftCardBalance(CertificateData, ResponseStructure);
			
		Else
			
			ResponseStructure.Error = True;
			ResponseStructure.ErrorMessage = NStr("vi = 'Không tìm thấy phiếu quà tặng';
													|ru = 'Подарочный сертификат не найден';
													|en = 'Gift card is not found'; fa = 'Gift card is not found';
													|it = 'Подарочный сертификат не найден';
													|pl = 'Gift card is not found';
													|tr = 'Hediye kartı bulunmadı'");
		EndIf;
		
		// Returning the response structure 
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "GetGiftCertificateDetails");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function GetGiftCertificateDetailsPOST(Query)
	
	Response = New HTTPServiceResponse(200);
		
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetResponseParametersGiftCardData(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	
	IncomingData = Query.GetBodyAsString();
	
	MethodParameters = New Structure;
	MethodParameters.Insert("HasErrors", False);
	MethodParameters.Insert("ErrorDescription", "");
	
	Try
		
		LoyaltyServiceOverridable.MethodParametersFromGetGiftCardDataRequest(IncomingData, MethodParameters);
		
		If MethodParameters.HasErrors Then
			
			ResponseStructure.Error = True;
			ResponseStructure.ErrorMessage = MethodParameters.ErrorDescription;
			
		Else
			
			LoyaltyServiceOverridable.GetGiftCardBalance(MethodParameters, ResponseStructure);
			
		EndIf;
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage,
			"MethodParametersFromGetGiftCardDataRequest");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function GetPromoCodeDataGET(Query)
	
	Try
		
		Response = New HTTPServiceResponse(200);
		
		UseLoyaltyServer = False;
		LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
		
		ResponseStructure 	= Undefined;
		LoyaltyService.GetResponseParametersPromoCodeData(ResponseStructure);
		
		If Not UseLoyaltyServer Then
			LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
			Return Response;
		EndIf;
		
		MethodParameters 	= Undefined;
		LoyaltyService.PromoCodeRequestParameters(Query, MethodParameters);
		
		If MethodParameters.PromoCode <> Undefined Then
			LoyaltyServiceOverridable.GetStateOfPromoCode(MethodParameters, ResponseStructure, True);
		EndIf;
		
		// Returning the response structure 
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "GetPromoCodeData");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function UnlockGiftCardPOST(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	If Not UseLoyaltyServer Then
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters   = Undefined;
		CertificateData = Undefined;
		LoyaltyService.GiftCardParameters(Query, MethodParameters);
		LoyaltyServiceOverridable.FindGiftCard(MethodParameters, CertificateData);
		
		If CertificateData.GiftCertificate <> Undefined Then
			LoyaltyService.UnlockGiftCard(CertificateData);
			MessageText = NStr("vi = 'Đã bỏ chặn phiếu quà tặng';
								|ru = 'Подарочный сертификат разблокирован';
								|en = 'Gift card is unlocked'; fa = 'Gift card is unlocked';
								|it = 'Подарочный сертификат разблокирован';
								|pl = 'Gift card is unlocked';
								|tr = 'Hediye kartının kilidi açıldı'");
		Else
			MessageText = NStr("vi = 'Không tìm thấy phiếu quà tặng';
								|ru = 'Подарочный сертификат не найден';
								|en = 'Gift card is not found'; fa = 'Gift card is not found';
								|it = 'Подарочный сертификат не найден';
								|pl = 'Gift card is not found';
								|tr = 'Hediye kartı bulunmadı'");
		EndIf;
		
		Response.SetBodyFromString(MessageText);
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "UnlockGiftCard");
		
	EndTry;
	
	Return Response;
	
EndFunction 

Function UnlockPromoCodePOST(Query)
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	If Not UseLoyaltyServer Then
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters   = Undefined;
		LoyaltyService.GiftCardParameters(Query, MethodParameters);
		
		LoyaltyService.RemoveReserveForUsingPromoCode(MethodParameters.PromoCode);
		MessageText = NStr("vi = 'Đã mở khóa mã khuyến mại.';
							|ru = 'Промокод разблокирован.';
							|en = 'Promo code is unlocked.'; fa = 'Promo code is unlocked.';
							|it = 'Промокод разблокирован.';
							|pl = 'Promo code is unlocked.';
							|tr = 'Promosyon kodunun kilidi açıldı.'");
			
		Response.SetBodyFromString(MessageText);
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage,
			"UnlockPromoCode");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function WriteOffGiftCardPOST(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	If Not UseLoyaltyServer Then
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters   = Undefined;
		CertificateData = Undefined;
		
		LoyaltyService.GiftCardParameters(Query, MethodParameters);
		LoyaltyService.AddParametersToWriteOffGiftCardMethod(Query, MethodParameters);
		LoyaltyServiceOverridable.FindGiftCard(MethodParameters, CertificateData);
		
		If CertificateData.GiftCertificate <> Undefined Then
			LoyaltyService.AdjustGiftCardBalance(CertificateData,
				MethodParameters.DebitedAmount, 0);
			MessageText = NStr("vi = 'Đã ghi giảm phiếu quà tặng với số tiền cụ thể';
								|ru = 'Подарочный сертификат успешно списан на указанную сумму';
								|en = 'Gift card is written off for the specified amount'; fa = 'Gift card is written off for the specified amount';
								|it = 'Подарочный сертификат успешно списан на указанную сумму';
								|pl = 'Gift card is written off for the specified amount';
								|tr = 'Hediye sertifikası, belirtilen miktar doğrultusunda başarıyla kayıttan düşüldü'");
		Else
			MessageText = NStr("vi = 'Không tìm thấy phiếu quà tặng';
								|ru = 'Подарочный сертификат не найден';
								|en = 'Gift card is not found'; fa = 'Gift card is not found';
								|it = 'Подарочный сертификат не найден';
								|pl = 'Gift card is not found';
								|tr = 'Hediye kartı bulunmadı'");
		EndIf;
		Response.SetBodyFromString(MessageText);
	
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage,
			"WriteOffGiftCard");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function UseAutomaticDiscountsGET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetResponseParametersUseAutomaticDiscounts(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		LoyaltyServiceOverridable.UseAutomaticDiscounts(ResponseStructure.UseAutomaticDiscounts);
		LoyaltyServiceOverridable.UseCounterpartyBonuses(ResponseStructure.UseCounterpartyBonuses);
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
	
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
	
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "RequestToUseAutomaticDiscounts");
		
	EndTry;
		
	Return Response;
	
EndFunction

Function CalculateAutoDiscountsGET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetResponseParametersCalculationOfDiscounts(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	UseAutomaticDiscounts = False;
	LoyaltyServiceOverridable.UseAutomaticDiscounts(UseAutomaticDiscounts);
	
	If Not UseAutomaticDiscounts Then
		LoyaltyService.FillInResponseAutomaticDiscounts(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	IncomingData		= Query.GetBodyAsString();
	CalculationParameters 	= Undefined;
 	LoyaltyServiceOverridable.DeserializeCalculationParameters(IncomingData, CalculationParameters);
	
	Try
	
		If CalculationParameters.HasErrors Then
			ResponseStructure.Error = True;
			ResponseStructure.ErrorMessage = CalculationParameters.ErrorDescription;
		Else
			LoyaltyServiceOverridable.CalculateAutoDiscounts(CalculationParameters, ResponseStructure);
			
			If CalculationParameters.ReturnCardDetails And CalculationParameters.BlockCard = "1"
					And Not ResponseStructure.LoyaltyCardDescription.CardNotFound Then
					
				CardData = ResponseStructure.LoyaltyCardDescription.LoyaltyCard;
				If CardData.BonusData.BonusCount > 0 And Not CardData.IsBlocked Then
					LoyaltyService.BlockBonuses(CalculationParameters.DiscountCard, CurrentSessionDate());
				EndIf;
				
			EndIf;
		EndIf;
	
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
	
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage,
			"CalculateAutoDiscounts");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function CalculateAutoDiscountsPOST(Query)
	
	Response = CalculateAutoDiscountsGET(Query);
	
	Return Response;
	
EndFunction

Function CheckGiftCardGET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	ResponseStructure = Undefined;
	LoyaltyService.GetResponseParametersForCheckingGiftCard(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters = Undefined;
		LoyaltyService.GiftCardParameters(Query, MethodParameters);
		LoyaltyServiceOverridable.CheckGiftCard(MethodParameters, ResponseStructure);
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
	
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage,
			"CheckingGiftCard");
		
	EndTry;
		
	Return Response;
	
EndFunction

Function GetControlledDiscountsGET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	If Not UseLoyaltyServer Then
		Return Response;
	EndIf;
	
	Try
		
		CalculationParameters 	= Undefined;
		ResponseStructure = Undefined;
		LoyaltyService.RequestParametersManagedDiscounts(Query, CalculationParameters);
		
		LoyaltyService.ListOfManagedDiscounts(ResponseStructure, CalculationParameters);
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage,
			"ListOfManagedDiscounts");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function GetDiscountsOnPaymentTypesGET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	If Not UseLoyaltyServer Then
		Return Response;
	EndIf;
	
	Try
		
		ResponseStructure = Undefined;
		LoyaltyService.ListOfDiscountsByPaymentType(ResponseStructure);
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage,
			"ListOfDiscountsByPaymentType");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function GetBalanceGET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetResponseParametersBalances(ResponseStructure);
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		IncomingData = Query.GetBodyAsString();
		ParametersForObtainingBalances = Undefined;
		LoyaltyServiceOverridable.ParametersFromGetBalancesRequest(IncomingData, ParametersForObtainingBalances);
		
		
		LoyaltyServiceOverridable.GetBalance(ParametersForObtainingBalances, ResponseStructure);
		
		// Returning the response structure 
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "GetBalance");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function GetBalancePOST(Query)
	
	Response = GetBalanceGET(Query);
	
	Return Response;
	
EndFunction

Function FindCustomerCardGET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetResponseParametersListOfLoyaltyCards(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters = Undefined;
		CustomerCard = Undefined;
		
		LoyaltyService.MethodParametersFromFindClientCardRequest(Query, MethodParameters);
		LoyaltyServiceOverridable.FindLoyaltyCards(MethodParameters, ResponseStructure);
		
		If MethodParameters.BlockCard = "1" And ResponseStructure.LoyaltyCardsList.Count() = 1 
				And ResponseStructure.LoyaltyCardsList[0].BonusData.BonusCount > 0
				And Not ResponseStructure.LoyaltyCardsList[0].IsBlocked Then
			
			GUIDMapsByLine = ResponseStructure.LoyaltyCardsList[0].CardGUID;
			LoyaltyServiceOverridable.GetCustomerCardWithUniqueIdentifier(GUIDMapsByLine,
				CustomerCard);
			LoyaltyService.BlockBonuses(CustomerCard, CurrentSessionDate());
			
		EndIf;
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "FindCustomerCard");
		
	EndTry;
		
	Return Response;
	
EndFunction

Function GetCardKindsGET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
		
	If Not UseLoyaltyServer Then
		Return Response;
	EndIf;
	
	Try
		
		ResponseStructure = Undefined;
		
		CalculationParameters 	= Undefined;
		LoyaltyService.RequestParametersTypesOfDiscountCards(Query, CalculationParameters);
		
		LoyaltyService.ListOfTypesOfDiscountCards(ResponseStructure, CalculationParameters);
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "GetCardKinds");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function GetSalesTurnoversGET(Query)
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetResponseParametersSalesTurnover(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters = Undefined;
		CustomerCard 	= Undefined;
		
		LoyaltyService.ClientCardDataParameters(Query, MethodParameters);
		LoyaltyServiceOverridable.FindCustomerCard(MethodParameters, CustomerCard);
		
		If CustomerCard <> Undefined Then
			
			ResponseStructure.ClientNotFound = False;
			
			LoyaltyServiceOverridable.FillInSalesTurnoverData(CustomerCard, ResponseStructure);
			
			LoyaltyServiceOverridable.FillInResponseStructureWithCardNumbers(CustomerCard, ResponseStructure);
			
		EndIf;
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "GetSalesTurnovers");
		
	EndTry;
	
	Return Response;
EndFunction

Function GetSellerDataGET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	If Not UseLoyaltyServer Then
		Return Response;
	EndIf;
	
	ResponseStructure = Undefined;
	
	Try
		
		CalculationParameters 	= Undefined;
		LoyaltyService.ParametersForRequestingListOfSellers(Query, CalculationParameters);
		LoyaltyService.ListOfEmployees(CalculationParameters, ResponseStructure);
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "ListOfSellers");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function GetBatchesBySelectionGET(Query)
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	If Not UseLoyaltyServer Then
		Return Response;
	EndIf;
	
	
	ResponseStructure = Undefined;

	Try
		
		CalculationParameters 	= Undefined;
		LoyaltyService.ParametersForRequestingListOfSeries(Query, CalculationParameters);
		LoyaltyService.FillInListOfBatches(CalculationParameters, ResponseStructure);
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "GetListOfBatchesOfGoods");
		
	EndTry;
	
	Return Response;
EndFunction

Function GetBatchDataGET(Query)
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetResponseParametersSeriesData(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters = Undefined;
		LoyaltyService.RequestParametersSeriesData(Query, MethodParameters);
		LoyaltyServiceOverridable.GetBatchData(MethodParameters, ResponseStructure);
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
	
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "GetBatchData");
		
	EndTry;
		
	Return Response;
EndFunction


Function GetRelevantPriceGET(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetParametersOfPriceRequestResponse(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters = Undefined;
		LoyaltyService.ParametersOfCurrentPriceRequest(Query, MethodParameters);
		LoyaltyServiceOverridable.GetRelevantPrice(MethodParameters, ResponseStructure);
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "GetRelevantPrice");
		
	EndTry;
		
	Return Response;
	
EndFunction

Function CombineBonusCardsPOST(Query)
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetTextMessageResponseParameters(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	IncomingData = Query.GetBodyAsString();
	MethodParameters = Undefined;
	
	Try
		LoyaltyServiceOverridable.MethodParametersFromCombineBonusCardsRequest(IncomingData, MethodParameters);
		LoyaltyServiceOverridable.CombineBonusCards(MethodParameters, ResponseStructure);
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "CombineBonusCards");
		
	EndTry;

	
	Return Response;
EndFunction

#Region LoyaltyServer_3_0_11

Function UnlockClientBonusesPOST3_0(Query)
	Response = New HTTPServiceResponse(200);
	
	Try
		
		UseLoyaltyServer = False;
		LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
		
		ResponseStructure = Undefined;
		LoyaltyService.GetTextMessageResponseParameters(ResponseStructure);
		
		If Not UseLoyaltyServer Then
			LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
			Return Response;
		EndIf;
		
		MethodParameters = Undefined;
		CustomerCard 	= Undefined;
		LoyaltyService.ClientCardDataParameters(Query, MethodParameters);
		LoyaltyServiceOverridable.FindCustomerCard(MethodParameters, CustomerCard);
		
		If CustomerCard <> Undefined Then
			LoyaltyService.UnlockBonuses(CustomerCard);
			MessageText = NStr("vi = 'Đã mở khóa điểm thưởng';
								|ru = 'Бонусы разблокированы';
								|en = 'Bonus points are unlocked'; fa = 'Bonus points are unlocked';
								|it = 'Бонусы разблокированы';
								|pl = 'Bonus points are unlocked';
								|tr = 'Bonusların kilidi açıldı'");
			ResponseStructure.TextMessage = MessageText;
		Else
			MessageText = NStr("vi = 'Chưa tìm thấy thẻ khách hàng';
								|ru = 'Карта клиента не найдена';
								|en = 'Customer card is not found'; fa = 'Customer card is not found';
								|it = 'Карта клиента не найдена';
								|pl = 'Customer card is not found';
								|tr = 'Müşteri kartı bulunmadı'");
			ResponseStructure.Error = True;
			ResponseStructure.ErrorMessage = MessageText;
		EndIf;
		
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "UnlockCustomerBonusPoints");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function WriteOFFClientBonusesPOST3_0(Query)
		
	Response = New HTTPServiceResponse(200);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetTextMessageResponseParameters(ResponseStructure);
		
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters = Undefined;
		CustomerCard 	= Undefined;
		LoyaltyService.ClientCardDataParameters(Query, MethodParameters);
		LoyaltyService.AddBonusMethodParameters(Query, MethodParameters);
		LoyaltyServiceOverridable.FindCustomerCard(MethodParameters, CustomerCard);
		
		If CustomerCard <> Undefined Then 
			If ValueIsFilled(MethodParameters.NumberOfBonusPoints) Then
				LoyaltyService.WriteOffAddBonuses(CustomerCard, MethodParameters.NumberOfBonusPoints, 0);
				MessageText = NStr("vi = 'Đã ghi giảm thành công điểm thưởng';
									|ru = 'Бонусы успешно списаны';
									|en = 'Bonus points are written off'; fa = 'Bonus points are written off';
									|it = 'Бонусы успешно списаны';
									|pl = 'Bonus points are written off';
									|tr = 'Bonuslar başarıyla kayıttan düşüldü'");
				ResponseStructure.TextMessage = MessageText;
			Else
				MessageText = NStr("vi = 'Chưa chỉ định số lượng điểm thưởng';
									|ru = 'Количество баллов не указано';
									|en = 'Number of bonus points is not specified'; fa = 'Number of bonus points is not specified';
									|it = 'Количество баллов не указано';
									|pl = 'Number of bonus points is not specified';
									|tr = 'Puan miktarı belirtilmedi'");
				ResponseStructure.Error = True;
				ResponseStructure.ErrorMessage = MessageText;
			EndIf;
		Else
			MessageText = NStr("vi = 'Chưa tìm thấy thẻ khách hàng';
								|ru = 'Карта клиента не найдена';
								|en = 'Customer card is not found'; fa = 'Customer card is not found';
								|it = 'Карта клиента не найдена';
								|pl = 'Customer card is not found';
								|tr = 'Müşteri kartı bulunmadı'");
			ResponseStructure.Error = True;
			ResponseStructure.ErrorMessage = MessageText;
		EndIf;
		
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage,
			"WriteOffCustomerBonusPoints");
		
	EndTry;
	
	Return Response;
EndFunction

Function UnlockGiftCardPOST3_0(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetTextMessageResponseParameters(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters   = Undefined;
		CertificateData = Undefined;
		LoyaltyService.GiftCardParameters(Query, MethodParameters);
		LoyaltyServiceOverridable.FindGiftCard(MethodParameters, CertificateData);
		
		If CertificateData.GiftCertificate <> Undefined Then
			LoyaltyService.UnlockGiftCard(CertificateData);
			ResponseStructure.TextMessage = NStr("vi = 'Đã mở khóa phiếu quà tặng.';
												|ru = 'Подарочный сертификат разблокирован.';
												|en = 'Gift card is unlocked.'; fa = 'Gift card is unlocked.';
												|it = 'Подарочный сертификат разблокирован.';
												|pl = 'Gift card is unlocked.';
												|tr = 'Hediye kartının kilidi açıldı.'");
		Else
			ResponseStructure.Error = True;
			ResponseStructure.ErrorMessage = NStr("vi = 'Không tìm thấy phiếu quà tặng.';
													|ru = 'Подарочный сертификат не найден.';
													|en = 'Gift card is not found.'; fa = 'Gift card is not found.';
													|it = 'Подарочный сертификат не найден.';
													|pl = 'Gift card is not found.';
													|tr = 'Hediye kartı bulunmadı.'");
		EndIf;
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "UnlockGiftCard");
		
	EndTry;
	
	Return Response;
EndFunction

Function WriteOffGiftCardPOST3_0(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetTextMessageResponseParameters(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters   = Undefined;
		CertificateData = Undefined;
		
		LoyaltyService.GiftCardParameters(Query, MethodParameters);
		LoyaltyService.AddParametersToWriteOffGiftCardMethod(Query, MethodParameters);
		LoyaltyServiceOverridable.FindGiftCard(MethodParameters, CertificateData);
		
		If CertificateData.GiftCertificate <> Undefined Then
			LoyaltyService.AdjustGiftCardBalance(CertificateData, MethodParameters.DebitedAmount, 0);
			ResponseStructure.TextMessage = NStr("vi = 'Đã ghi giảm thành công phiếu quà tặng với số tiền cụ thể.';
												|ru = 'Подарочный сертификат успешно списан на указанную сумму.';
												|en = 'Gift card is written off for the specified amount.'; fa = 'Gift card is written off for the specified amount.';
												|it = 'Gift card is written off for the specified amount.';
												|pl = 'Gift card is written off for the specified amount.';
												|tr = 'Hediye kartı, belirtilen miktar doğrultusunda başarıyla kayıttan düşüldü.'");
		Else
			ResponseStructure.Error = True;
			ResponseStructure.ErrorMessage = NStr("vi = 'Không tìm thấy phiếu quà tặng.';
													|ru = 'Подарочный сертификат не найден.';
													|en = 'Gift card is not found.'; fa = 'Gift card is not found.';
													|it = 'Подарочный сертификат не найден.';
													|pl = 'Gift card is not found.';
													|tr = 'Hediye kartı bulunmadı.'");
			
		EndIf;
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
	
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "WriteOffGiftCard");
		
	EndTry;
	
	Return Response;
EndFunction

Function UnblockPromoCodePOST3_0(Query)
	
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetTextMessageResponseParameters(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters   = Undefined;
		LoyaltyService.PromoCodeRequestParameters(Query, MethodParameters);
		
		LoyaltyService.RemoveReserveForUsingPromoCode(MethodParameters.PromoCode);
		
		ResponseStructure.TextMessage = NStr("vi = 'Đã mở khóa mã khuyến mại.';
											|ru = 'Промокод разблокирован.';
											|en = 'Promo code is unlocked.'; fa = 'Promo code is unlocked.';
											|it = 'Промокод разблокирован.';
											|pl = 'Promo code is unlocked.';
											|tr = 'Promosyon kodunun kilidi açıldı.'");
			
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage,
			"UnlockPromoCode");
		
	EndTry;
	
	Return Response;
	
EndFunction

Function AccrueCustomerBonusPointsPOST(Query)
	Response = New HTTPServiceResponse(200);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetTextMessageResponseParameters(ResponseStructure);
		
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		
		MethodParameters = Undefined;
		CustomerCard 	= Undefined;
		LoyaltyService.ClientCardDataParameters(Query, MethodParameters);
		LoyaltyService.AddBonusMethodParameters(Query, MethodParameters);
		LoyaltyServiceOverridable.FindCustomerCard(MethodParameters, CustomerCard);
		
		If CustomerCard <> Undefined Then
			If ValueIsFilled(MethodParameters.NumberOfBonusPoints) Then
				LoyaltyService.WriteOffAddBonuses(CustomerCard, 0, MethodParameters.NumberOfBonusPoints);
				MessageText = NStr("vi = 'Đã tính thành công điểm thưởng';
									|ru = 'Бонусы успешно начислины';
									|en = 'Bonus points are accrued'; fa = 'Bonus points are accrued';
									|it = 'Bonus points are accrued';
									|pl = 'Bonus points are accrued';
									|tr = 'Bonuslar başarıyla yatırıldı'");
				ResponseStructure.TextMessage = MessageText;
			Else
				MessageText = NStr("vi = 'Chưa chỉ ra số lượng điểm thưởng';
									|ru = 'Количество баллов не указано';
									|en = 'Number of bonus points is not specified'; fa = 'Number of bonus points is not specified';
									|it = 'Количество баллов не указано';
									|pl = 'Number of bonus points is not specified';
									|tr = 'Puan miktarı belirtilmedi'");
				ResponseStructure.Error = True;
				ResponseStructure.ErrorMessage = MessageText;
			EndIf;
		Else
			MessageText = NStr("vi = 'Không tìm thấy thẻ khách hàng';
								|ru = 'Карта клиента не найдена';
								|en = 'Customer card is not found'; fa = 'Customer card is not found';
								|it = 'Карта клиента не найдена';
								|pl = 'Customer card is not found';
								|tr = 'Müşteri kartı bulunmadı'");
			ResponseStructure.Error = True;
			ResponseStructure.ErrorMessage = MessageText;
		EndIf;
		
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
		
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription, ErrorMessage, "AccrueCustomerBonusPoints");
		
	EndTry;
	
	Return Response;
EndFunction

Function AccrueGiftCardPOST(Query)
	Response = New HTTPServiceResponse(200);
	
	UseLoyaltyServer = False;
	LoyaltyServiceOverridable.UseLoyaltyServer(Response, UseLoyaltyServer);
	
	ResponseStructure = Undefined;
	LoyaltyService.GetTextMessageResponseParameters(ResponseStructure);
	
	If Not UseLoyaltyServer Then
		LoyaltyService.FillInDisabledLoyaltyServerResponse(ResponseStructure, Response);
		Return Response;
	EndIf;
	
	Try
		MethodParameters   = Undefined;
		CertificateData = Undefined;
		
		LoyaltyService.GiftCardParameters(Query, MethodParameters);
		LoyaltyService.AddParametersToAddGiftCardMethod(Query, MethodParameters);
		LoyaltyServiceOverridable.FindGiftCard(MethodParameters, CertificateData);
		
		If CertificateData.GiftCertificate <> Undefined Then
			LoyaltyService.AdjustGiftCardBalance(CertificateData, 0, MethodParameters.AccrualAmount);
			LoyaltyServiceOverridable.SetStatusOfGift(CertificateData, MethodParameters.AccrualAmount > 0);
			ResponseStructure.TextMessage = NStr("vi = 'Đã tính thành công phiếu quà tặng với số tiền cụ thể.';
												|ru = 'Подарочный сертификат успешно начислен на указанную сумму.';
												|en = 'The specified amount is accrued on the gift card'; fa = 'The specified amount is accrued on the gift card';
												|it = 'The specified amount is accrued on the gift card';
												|pl = 'The specified amount is accrued on the gift card';
												|tr = 'Hediye kartı, belirtilen miktar doğrultusunda başarıyla yatırıldı.'");
		Else
			ResponseStructure.Error = True;
			ResponseStructure.ErrorMessage = NStr("vi = 'Không tìm thấy phiếu quà tặng.';
													|ru = 'Подарочный сертификат не найден.';
													|en = 'Gift card is not found.'; fa = 'Gift card is not found.';
													|it = 'Подарочный сертификат не найден.';
													|pl = 'Gift card is not found.';
													|tr = 'Hediye kartı bulunmadı.'");
			
		EndIf;
		
		// Returning the response structure
		StructureOfJSONResponse = New JSONWriter;
		StructureOfJSONResponse.SetString();
		WriteJSON(StructureOfJSONResponse, ResponseStructure);
		
		Response.SetBodyFromString(StructureOfJSONResponse.Close());
	
	Except
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Response = LoyaltyService.FixLoyaltyServiceError(ErrorDescription,
			ErrorMessage, "AccrueGiftCard");
		
	EndTry;
	
	Return Response;
EndFunction
#EndRegion

#EndRegion
