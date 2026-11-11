
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not UsersClientServer.IsExternalUserSession() Then
		Cancel = True;
		Return;
	EndIf;

	FillPropertyValues(ThisObject, PartnersAndCounterpartiesServerCall.DataOfAuthorizedExternalUser());
	
	If Partner = Undefined Or Partner.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf;
	
	FillInWelcomeInformation();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If (EventName = "Write_SalesOrder" Or EventName = "Write_Partners")
		And Parameter.Property("Partner")
		And Parameter.Partner = Partner Then
		
		FillInWelcomeInformation();
		
	ElsIf EventName = "Write_ContactPersonsForPartners" 
		And Parameter.Property("Owner")
		And Parameter.Owner = Partner Then
		
		FillInWelcomeInformation();
		
	ElsIf EventName = "Write_CustomerShoppingCart" And Parameter.Property("AuthorizationObject") Then
		
		If TypeOf(Parameter.AuthorizationObject) = Type("CatalogRef.Partners") 
			And Parameter.AuthorizationObject = Partner Then
			
			FillInWelcomeInformation();
			
		ElsIf TypeOf(Parameter.AuthorizationObject) = Type("CatalogRef.ContactPersonsForPartners") 
			And Parameter.AuthorizationObject = ContactPerson Then
			
			FillInWelcomeInformation();
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ComplimentaryInformationOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	If StrOccurrenceCount(EventData.Href,"cart") > 0 Then
		OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.CustomerShoppingCart",
		,
		GetWindows()[0],
		,
		ApplicationWindow());
	ElsIf  StrOccurrenceCount(EventData.Href,"orders") > 0 Then
		
		OpenForm("Document.SalesOrder.Form.SelfServiceWorkplaceListForm",
		,
		GetWindows()[0],
		,
		ApplicationWindow());
		
	ElsIf  StrOccurrenceCount(EventData.Href,"Change_information_partner") > 0 Then
		
		OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.ChangingContactInformation",
		,
		GetWindows()[0]);
		
	ElsIf  StrOccurrenceCount(EventData.Href,"List_of_polls") > 0 Then
		
		OpenForm("DataProcessor.AvailableQuestionnaires.Form.Form",
		,
		GetWindows()[0],
		,
		ApplicationWindow());
		
	ElsIf  StrOccurrenceCount(EventData.Href,"Change_information_contact") > 0 Then
		
		OpenForm("Catalog.ContactPersonsForPartners.Form.ItemForm",
		New Structure("Key",ContactPerson),
		GetWindows()[0]);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function ApplicationWindow()
	
	Return ?(ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2,GetWindows()[0], Undefined);
	
EndFunction

&AtServer
Procedure FillInWelcomeInformation()
	
	If PartnerAuthorized Then
		ComplimentaryInformation = DataProcessors.SelfServiceWorkplacePartners.GetTemplate("MainPage").GetText();
	Else
		ComplimentaryInformation = DataProcessors.SelfServiceWorkplacePartners.GetTemplate("HomeContactPerson").GetText();
	EndIf;
	
	SelfServiceServer.SetBackgroundColorOfHTML5Information(ComplimentaryInformation);
	
	CurRequestNumber = 0;
	MatchingInformationToRequestNumbers = New Map;
	
	RightToViewShoppingCart           = AccessRight("View", Metadata.InformationRegisters.CustomerShoppingCart);
	RightToViewCustomerSOrder      = AccessRight("View", Metadata.Documents.SalesOrder);
	RightToViewSettlementsWithClients = AccessRight("View", Metadata.AccumulationRegisters.CustomersARAPAccounting);
	RightToViewQuestionnaire             = AccessRight("View", Metadata.Documents.Questionnaire);
	RightToChangePartner           = IsInRole("SelfServiceWorkplaceExternalUserEdutCustomerContactDetails");
	RightToChangeContactPersons    = AccessRight("Update", Metadata.Catalogs.ContactPersonsForPartners);
	
	Query = New Query;
	
	Query.Text = "
	|SELECT ALLOWED
	|	Partners.DescriptionFull,
	|	Partners.Description
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	Partners.Ref = &Partner
	|;
	|	
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	PartnersContactInformation.Presentation,
	|	PartnersContactInformation.Type,
	|	PartnersContactInformation.Kind
	|FROM
	|	Catalog.Partners.ContactInformation AS PartnersContactInformation
	|WHERE
	|	PartnersContactInformation.Ref = &Partner
	|";
	
	MatchingInformationToRequestNumbers.Insert("PartnerData", CurRequestNumber);
	MatchingInformationToRequestNumbers.Insert("DataContactInformationOfPartner", CurRequestNumber + 1);
	CurRequestNumber = CurRequestNumber + 2;
	
	If RightToViewShoppingCart Then
		
		Query.Text = Query.Text + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	COUNT(NestedQuery.Products) AS GoodsQuantity
		|FROM
		|	(SELECT DISTINCT
		|		CustomerShoppingCart.Products AS Products,
		|		CustomerShoppingCart.Characteristic AS Characteristic
		|	FROM
		|		InformationRegister.CustomerShoppingCart AS CustomerShoppingCart
		|	WHERE
		|		CustomerShoppingCart.AuthorizationObject = &AuthorizationObject) AS NestedQuery
		|";
		
		MatchingInformationToRequestNumbers.Insert("BucketData", CurRequestNumber);
		CurRequestNumber = CurRequestNumber + 1;
	
	EndIf;
	
	If RightToViewCustomerSOrder Then
		
		Query.Text = Query.Text + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	COUNT(DISTINCT SalesOrder.Ref) AS Count
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|		INNER JOIN Catalog.TermsOfSale AS TermsOfSale
		|		ON SalesOrder.Terms = TermsOfSale.Ref
		|WHERE
		|	SalesOrder.Posted
		|	AND NOT SalesOrder.Status = VALUE(Enum.SalesOrderStatuses.Closed)
		|	AND SalesOrder.Partner = &Partner
		|	AND TermsOfSale.AvailableToExternalUsers
		|";
		
		MatchingInformationToRequestNumbers.Insert("TheseOrders", CurRequestNumber);
		CurRequestNumber = CurRequestNumber + 1;
		
	EndIf;
	
	If RightToViewSettlementsWithClients Then
		
		Query.Text = Query.Text + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	CASE
		|		WHEN CustomersARAPAccountingBalance.SumBalance > 0
		|			THEN CustomersARAPAccountingBalance.SumBalance
		|		ELSE 0
		|	END AS SumBalance,
		|	CASE
		|		WHEN CustomersARAPAccountingBalance.AmountDueBalance > 0
		|			THEN CustomersARAPAccountingBalance.AmountDueBalance
		|		ELSE 0
		|	END AS AmountDueBalance,
		|	CustomersARAPAccountingBalance.Currency
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject.Partner = &Partner) AS CustomersARAPAccountingBalance
		|";
		
		MatchingInformationToRequestNumbers.Insert("DataSettlementsWithCustomers", CurRequestNumber);
		CurRequestNumber = CurRequestNumber + 1;
		
	EndIf;
	
	If Not PartnerAuthorized Then
		
		Query.Text = Query.Text + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ContactPersonsForPartners.Description,
		|	ContactPersonsForPartners.JobTitleOnBusinessCard
		|FROM
		|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
		|WHERE
		|	ContactPersonsForPartners.Ref = &ContactPerson
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ContactPersonsOfPartnersContactInformation.Type,
		|	ContactPersonsOfPartnersContactInformation.Kind,
		|	ContactPersonsOfPartnersContactInformation.Presentation
		|FROM
		|	Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
		|WHERE
		|	ContactPersonsOfPartnersContactInformation.Ref = &ContactPerson
		|";
		
		Query.SetParameter("ContactPerson", ContactPerson);
		MatchingInformationToRequestNumbers.Insert("DataContactPerson", CurRequestNumber);
		MatchingInformationToRequestNumbers.Insert("DataContactInformationOfContactPerson", CurRequestNumber + 1);
		CurRequestNumber = CurRequestNumber + 2;
		
	EndIf;
	
	Query.SetParameter("AuthorizationObject", ?(PartnerAuthorized, Partner, ContactPerson));
	Query.SetParameter("Partner",Partner);
	Query.SetParameter("CurrentDate",CurrentSessionDate());
	
	Result = Query.ExecuteBatch();
	
	PartnerName = "";
	SelectionPartnerName = Result[MatchingInformationToRequestNumbers.Get("PartnerData")].Select();
	If SelectionPartnerName.Next() Then
		PartnerName = ?(IsBlankString(SelectionPartnerName.DescriptionFull),SelectionPartnerName.Description,SelectionPartnerName.DescriptionFull);
	EndIf;
	ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#PartnerFullName#",PartnerName);
	
	If RightToViewQuestionnaire Then
		NumberOfQuestionnaires = 0;
		QuestionnairesTable = Surveys.TableOfQuestionnairesAvailableToRespondent(?(PartnerAuthorized, Partner, ContactPerson));
		If QuestionnairesTable <> Undefined Then
			NumberOfQuestionnaires = QuestionnairesTable.Count();
		EndIf;
		ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#NumberOfAvaibleQuestionnary#",NumberOfQuestionnaires);
		ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#QN#","");
	Else
		TMCommonUseClientServer.RemoveSubstringFromString(ComplimentaryInformation, "#QN#");
	EndIf;
	
	If Not PartnerAuthorized Then
		NameOfContactPerson = "";
		SampleContactPersonInformation = Result[MatchingInformationToRequestNumbers.Get("DataContactPerson")].Select();
		If SampleContactPersonInformation.Next() Then
			NameOfContactPerson = SampleContactPersonInformation.Description 
			                              + ?(IsBlankString(SampleContactPersonInformation.JobTitleOnBusinessCard),
			                                  "",
			                                  ", " + SampleContactPersonInformation.JobTitleOnBusinessCard);
		EndIf;
		ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#ContactPersonName#",NameOfContactPerson);
	EndIf;
	
	QueryNumber = MatchingInformationToRequestNumbers.Get("BucketData");
	If QueryNumber = Undefined Then
		TMCommonUseClientServer.RemoveSubstringFromString(ComplimentaryInformation, "#CD#");
	Else
		SelectionOfBasketProducts = Result[QueryNumber].Select();
		If SelectionOfBasketProducts.Next() Then
			ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#ItemsInTheCart#",SelectionOfBasketProducts.GoodsQuantity);
		Else
			ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#ItemsInTheCart#",0);
		EndIf;
		ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#CD#","");
	EndIf;
	
	QueryNumber = MatchingInformationToRequestNumbers.Get("TheseOrders");
	If QueryNumber = Undefined Then
		TMCommonUseClientServer.RemoveSubstringFromString(ComplimentaryInformation, "#OD#");
	Else
		If GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
			ComplimentaryInformation = StrReplace(ComplimentaryInformation, 
			"#OrdersProcessed#", 
			NStr("vi = 'Xử lý đơn hàng tại thời điểm này -%NumberOfOrdersProcessed%.';
				|ru = 'Обрабатывается заказов в данный момент - %NumberOfOrdersProcessed%.';
				|en = 'Orders processing now - %NumberOfOrdersProcessed%.'; fa = 'Orders processing now - %NumberOfOrdersProcessed%.';
				|it = 'Elaborazione degli ordini in questo momento - %NumberOfOrdersProcessed%.';
				|pl = 'Przetwarzano zamówień w tej chwili - %NumberOfOrdersProcessed%.';
				|tr = 'Şu anda işlenmekte olan siparişler - %NumberOfOrdersProcessed%.'"));
		Else
			ComplimentaryInformation = StrReplace(ComplimentaryInformation, 
			"#OrdersProcessed#", 
			NStr("vi = 'Tổng số %NumberOfOrdersProcessed% đơn hàng của bạn.';
				|ru = 'Всего %NumberOfOrdersProcessed% ваших заказов.';
				|en = 'Total %NumberOfOrdersProcessed% of your orders.'; fa = 'Total %NumberOfOrdersProcessed% of your orders.';
				|it = 'In tutto %NumberOfOrdersProcessed% dei vostri ordini.';
				|pl = 'Łącznie %NumberOfOrdersProcessed% twoich zamówień.';
				|tr = 'Sizin toplam %NumberOfOrdersProcessed% siparişleriniz.'"));
		EndIf; 
		
		SampleOrdersInProcessing = Result[QueryNumber].Select();
		If SampleOrdersInProcessing.Next() Then
			ComplimentaryInformation = StrReplace(ComplimentaryInformation,"%NumberOfOrdersProcessed%",SampleOrdersInProcessing.Count);
		Else
			ComplimentaryInformation = StrReplace(ComplimentaryInformation,"%NumberOfOrdersProcessed%",0);
		EndIf;
		ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#OD#","");
	EndIf;
	
	QueryNumber = MatchingInformationToRequestNumbers.Get("DataSettlementsWithCustomers");
	If QueryNumber = Undefined Then
		TMCommonUseClientServer.RemoveSubstringFromString(ComplimentaryInformation, "#CS#");
	Else
		If Not Result[QueryNumber].IsEmpty() Then
			LineAmountBalance = "";
			AmountDueLineBalance = "";
			SampleSettlements = Result[QueryNumber].Select();
			While SampleSettlements.Next() Do
				LineAmountBalance   = LineAmountBalance + ?(SampleSettlements.SumBalance > 0,
				                                              String(SampleSettlements.SumBalance) + " " + String(SampleSettlements.Currency)+ " ",
				                                              "");
				AmountDueLineBalance = AmountDueLineBalance + ?(SampleSettlements.AmountDueBalance > 0,
				                                                String(SampleSettlements.AmountDueBalance) + " " + String(SampleSettlements.Currency)+ " ",
				                                                "");
			EndDo; 
			ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#CurrentDebt#",
			                                       ?(IsBlankString(LineAmountBalance),NStr("vi = 'không';
																							|ru = 'нет';
																							|en = 'no'; fa = 'no';
																							|it = 'non ci sono';
																							|pl = 'nie';
																							|tr = 'hayır'"),LineAmountBalance));
			ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#CurrentDebtOnOrders#",
			                                       ?(IsBlankString(AmountDueLineBalance),NStr("vi = 'không';
																								|ru = 'нет';
																								|en = 'no'; fa = 'no';
																								|it = 'non ci sono';
																								|pl = 'nie';
																								|tr = 'hayır'"),AmountDueLineBalance ));
		Else
			ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#CurrentDebt#",NStr("vi = 'không';
																								|ru = 'нет';
																								|en = 'no'; fa = 'no';
																								|it = 'non ci sono';
																								|pl = 'nie';
																								|tr = 'hayır'"));
			ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#CurrentDebtOnOrders#",NStr("vi = 'không';
																										|ru = 'нет';
																										|en = 'no'; fa = 'no';
																										|it = 'non ci sono';
																										|pl = 'nie';
																										|tr = 'hayır'"));
		EndIf;
		ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#CS#","");
	EndIf;
	
	If Result[MatchingInformationToRequestNumbers.Get("DataContactInformationOfPartner")].IsEmpty() Then
		ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#ContactInformation#",NStr("vi = 'chưa chỉ ra.';
																									|ru = 'не указана.';
																									|en = 'not specified.'; fa = 'not specified.';
																									|it = 'non indicata.';
																									|pl = 'nie określono.';
																									|tr = 'belirtilmedi.'"));
	Else
		CIRow = "";
		KiSelection = Result[MatchingInformationToRequestNumbers.Get("DataContactInformationOfPartner")].Select();
		While KiSelection.Next() Do
			If Not ValueIsFilled(KiSelection.Kind) Then
				Continue;
			EndIf;
			CIRow = CIRow + String(KiSelection.Kind) + ": " + String(KiSelection.Presentation) + "<br>"
		EndDo;
		ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#ContactInformation#",
		                                       ?(IsBlankString(CIRow),NStr("vi = 'chưa chỉ ra.';
																			|ru = 'не указана.';
																			|en = 'not specified.'; fa = 'not specified.';
																			|it = 'non indicata.';
																			|pl = 'nie określono.';
																			|tr = 'belirtilmedi.'"),CIRow));
	EndIf;
	
	If Not PartnerAuthorized Then
		If Result[MatchingInformationToRequestNumbers.Get("DataContactInformationOfContactPerson")].IsEmpty() Then
			ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#ContactInformationContactPerson#",NStr("vi = 'chưa chỉ ra.';
																													|ru = 'не указана.';
																													|en = 'not specified.'; fa = 'not specified.';
																													|it = 'non indicata.';
																													|pl = 'nie określono.';
																													|tr = 'belirtilmedi.'"));
		Else
			CIRow = "";
			KICKLSelection = Result[MatchingInformationToRequestNumbers.Get("DataContactInformationOfContactPerson")].Select();
			While KICKLSelection.Next() Do
				CIRow = CIRow + String(KICKLSelection.Kind) + ": " + String(KICKLSelection.Presentation) + "<br>"
			EndDo;
			ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#ContactInformationContactPerson#",
			                                       ?(IsBlankString(CIRow),NStr("vi = 'chưa chỉ ra.';
																				|ru = 'не указана.';
																				|en = 'not specified.'; fa = 'not specified.';
																				|it = 'non indicata.';
																				|pl = 'nie określono.';
																				|tr = 'belirtilmedi.'"),CIRow));
		EndIf;
		
		If RightToChangeContactPersons Then
			ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#CC#","");
		Else
			TMCommonUseClientServer.RemoveSubstringFromString(ComplimentaryInformation, "#CC#");
		EndIf;
		
	EndIf;
	
	If RightToChangePartner Then
		ComplimentaryInformation = StrReplace(ComplimentaryInformation,"#CP#","");
	Else
		TMCommonUseClientServer.RemoveSubstringFromString(ComplimentaryInformation, "#CP#");
	EndIf;
	
EndProcedure

#EndRegion
