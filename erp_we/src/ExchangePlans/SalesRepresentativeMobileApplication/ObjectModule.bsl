#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	NodeAlreadyExists = MobileApps.NodeToConnectToExists(User, MobileDevice, Ref);	
	
	If NodeAlreadyExists Then
		MessageText = NStr("vi = 'Đã tồn tại tùy chỉnh đối với đại diện thương mại %User% và máy tính xách tay %MobileDevice%';
							|ru = 'Настройка для торгового представителя %User% и мобильного компьютера %MobileDevice% уже существует';
							|en = 'Setting for sales representative %User% and mobile computer %MobileDevice% already exists'; fa = 'Setting for sales representative %User% and mobile computer %MobileDevice% already exists';
							|it = 'Impostazione per il rappresentante commerciale %User% e computer portatile%MobileDevice% esistente';
							|pl = 'Ustawienie dla przedstawiciela handlowego %User% i komputera mobilnego %MobileDevice% już istnieje';
							|tr = 'Satış temsilcisi %User% ve mobil bilgisayar %MobileDevice% için ayarlar zaten mevcut'");
		MessageText = StrReplace(MessageText, "%User%", User);
		MessageText = StrReplace(MessageText, "%MobileDevice%", MobileDevice);
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
		
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Code = "";
	Description = "";
	User = Undefined;
	MobileDevice = Undefined;
	UserName = "";
	Password = "";
	StorageOfExchangeSchemeFilter = Undefined;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	// This node does not require checking the filling in of a number of details
	If Ref = ExchangePlans.SalesRepresentativeMobileApplication.ThisNode() Then
		NotCheckedAttributeArray.Add("User");
		NotCheckedAttributeArray.Add("MobileDevice");
		NotCheckedAttributeArray.Add("MobileApplicationVersion");
		NotCheckedAttributeArray.Add("UseContactDetails");
		NotCheckedAttributeArray.Add("UserName");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);

EndProcedure

#EndRegion

#EndIf