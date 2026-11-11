
#Region FormEventHandlers
// Code of procedures and functions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	Employee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	ShowProductPhotos = Parameters.ShowProductPhotos;
	EmployeeType = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.EmployeeTypeCourier();
	UpdateFormData();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	CurrentOrder = Settings.Get("CurrentOrder");
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateListOfOrders" Then
		UpdateFormData();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfOrdersAssignedToMe

&AtClient
Procedure ListOfOrdersCurrentSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Items.ListOfOrdersCurrent.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.ListOfOrdersCurrentDeliveryAddressPresentation Then
		ShowMap(CurrentRow);
	Else
		
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("ReferenceOrder", CurrentRow.ReferenceOrder);
		FormOpenParameters.Insert("ShowProductPhotos", ShowProductPhotos);
			
		OpenForm(
			"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ReferenceCard",
			FormOpenParameters,
			ThisForm,,,,,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTheListOfUnallocatedOrders

&AtClient
Procedure TheListOfOrdersIsAsFollowsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Items.TheListOfOrdersIsAsFollows.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.TheListOfOrdersIsAsFollowsDeliveryAddressPresentation Then
		ShowMap(CurrentRow);
	Else
		
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("ReferenceOrder", CurrentRow.ReferenceOrder);
		FormOpenParameters.Insert("ShowProductPhotos", ShowProductPhotos);
			
		OpenForm(
			"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ReferenceCard",
			FormOpenParameters,
			ThisForm,,,,,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CallTheBuyer(Command)
	
#If MobileClient Then
	
	If Not TelephonyTools.NumberDialingSupported() Then
		Return;
	EndIf;
	
	If ListOfOrdersCurrent.Count() = 0 Then
		Return;
	EndIf;
	
	CurrentRow = ListOfOrdersCurrent[0];
	PhoneNumber = PhoneNumberOfContactPersonFromDocument(CurrentRow.ReferenceOrder);
	
	If PhoneNumber <> "" Then
		TelephonyTools.DialNumber(PhoneNumber, False);
	EndIf;
	
#EndIf
	
EndProcedure

&AtClient
Procedure MakeItCurrent(Command)
	
	CurrentRow = Items.TheListOfOrdersIsAsFollows.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CurrentOrder = CurrentRow.ReferenceOrder;
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure UpdateForm(Command)
	
	UpdateFormData();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function PhoneNumberOfContactPersonFromDocument(ReferenceOrder)
	
	Return DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.PhoneNumberOfContactPersonFromDocument(ReferenceOrder);
	
EndFunction

&AtServer
Procedure UpdateFormData()
	
	Query = New Query();
	Query.Text = "SELECT
	|	AssemblyAndDeliveryStatuses.ReferenceOrder AS ReferenceOrder,
	|	CASE
	|		WHEN AssemblyAndDeliveryStatuses.ReferenceOrder = &CurrentOrder
	|			THEN 1
	|		ELSE 0
	|	END AS CurrentOrder,
	|	AssemblyAndDeliveryStatuses.Status AS Status,
	|	Documents.Warehouse AS Warehouse,
	|	Documents.Courier AS Courier,
	|	Documents.Number AS Number,
	|	Documents.DateOfShipment AS DeliveryDate,
	|	Documents.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	Documents.DeliveryTimeTo AS DeliveryTimeTo,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	Documents.DeliveryAddress AS DeliveryAddressPresentation,
	|	Documents.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	Documents.AdditionalDeliveryInformation AS Comment,
	|	Documents.Currency AS Currency,
	|	Documents.PaymentMethod AS PaymentMethod,
	|	CASE
	|		WHEN Documents.ContactPerson = VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
	|			THEN Partners.Description
	|		ELSE ContactPersons.Description
	|	END AS ContactPersonPresentation,
	|	Documents.Organization AS Organization
	|INTO TemporaryDisposalTable
	|FROM
	|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|		INNER JOIN Document.SalesOrder AS Documents
	|		ON ((CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.SalesOrder)) = Documents.Ref)
	|		LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersons
	|		ON (Documents.ContactPerson = ContactPersons.Ref)
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON (Documents.Partner = Partners.Ref)
	|WHERE
	|	AssemblyAndDeliveryStatuses.Status IN (&Statuses)
	|	AND Documents.Courier = &Employee
	|	AND Documents.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	AssemblyAndDeliveryStatuses.ReferenceOrder,
	|	CASE
	|		WHEN AssemblyAndDeliveryStatuses.ReferenceOrder = &CurrentOrder
	|			THEN 1
	|		ELSE 0
	|	END,
	|	AssemblyAndDeliveryStatuses.Status,
	|	Documents.Warehouse,
	|	Documents.Courier,
	|	Documents.Number,
	|	Documents.Date,
	|	Documents.DeliveryTimeFrom,
	|	Documents.DeliveryTimeTo,
	|	Documents.DocumentAmount,
	|	Documents.DeliveryAddress,
	|	Documents.DeliveryAddressFieldValues,
	|	Documents.AdditionalDeliveryInformation,
	|	Documents.Currency,
	|	Documents.PaymentMethod,
	|	CASE
	|		WHEN Documents.ContactPerson = VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
	|			THEN Partners.Description
	|		ELSE ContactPersons.Description
	|	END,
	|	Documents.Organization
	|FROM
	|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|		INNER JOIN Document.CustomerInvoice AS Documents
	|		ON ((CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.CustomerInvoice)) = Documents.Ref)
	|		LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersons
	|		ON (Documents.ContactPerson = ContactPersons.Ref)
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON (Documents.Partner = Partners.Ref)
	|WHERE
	|	AssemblyAndDeliveryStatuses.Status IN (&Statuses)
	|	AND Documents.Courier = &Employee
	|	AND Documents.Posted
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CashAccounts.Owner AS Organization,
	|	CashAccounts.Ref AS CashAccount
	|INTO CheckoutTemporaryTable
	|FROM
	|	TemporaryDisposalTable AS DisposalTable
	|		INNER JOIN Catalog.CashAccounts AS CashAccounts
	|		ON DisposalTable.Organization = CashAccounts.Owner
	|WHERE
	|	CashAccounts.DeletionMark = FALSE
	|	AND CashAccounts.OperationalCashAccount = TRUE
	|	AND CashAccounts.Individual = &Employee
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DisposalTable.ReferenceOrder AS ReferenceOrder,
	|	DisposalTable.Status AS Status,
	|	SUM(ISNULL(CustomersARAPAccounting.AmountDueBalance, 0)) AS AmountToPay
	|INTO TemporaryTableForPaymentIntermediate
	|FROM
	|	TemporaryDisposalTable AS DisposalTable
	|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(,) AS CustomersARAPAccounting
	|		ON DisposalTable.ReferenceOrder = CustomersARAPAccounting.ARAPObject.Object
	|GROUP BY
	|	DisposalTable.ReferenceOrder,
	|	DisposalTable.Status
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableForPayment.ReferenceOrder AS ReferenceOrder,
	|	TemporaryTableForPayment.AmountToPay AS AmountToPay,
	|	SUM(CASE
	|		WHEN CashAccountBalance.CashAccount = CashAccountsTable.CashAccount
	|			THEN CASE
	|				WHEN CashAccountBalance.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN CashAccountBalance.Sum
	|				ELSE -CashAccountBalance.Sum
	|			END
	|		ELSE 0
	|	END) AS AmountToBePaidCourier
	|INTO TemporaryTableForPayment
	|FROM
	|	TemporaryTableForPaymentIntermediate AS TemporaryTableForPayment
	|		LEFT JOIN AccumulationRegister.CashAccountBalance AS CashAccountBalance
	|		ON TemporaryTableForPayment.ReferenceOrder = CashAccountBalance.ARAPObject.Object
	|		LEFT JOIN CheckoutTemporaryTable AS CashAccountsTable
	|		ON (CashAccountBalance.Organization = CashAccountsTable.Organization)
	|GROUP BY
	|	TemporaryTableForPayment.ReferenceOrder,
	|	TemporaryTableForPayment.AmountToPay
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DisposalTable.ReferenceOrder AS ReferenceOrder,
	|	DisposalTable.CurrentOrder AS CurrentOrder,
	|	DisposalTable.Status AS Status,
	|	DisposalTable.Warehouse AS Warehouse,
	|	DisposalTable.Courier AS Courier,
	|	DisposalTable.Number AS Number,
	|	DisposalTable.DeliveryDate AS DeliveryDate,
	|	DisposalTable.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	DisposalTable.DeliveryTimeTo AS DeliveryTimeTo,
	|	DisposalTable.DocumentAmount AS DocumentAmount,
	|	DisposalTable.DeliveryAddressPresentation AS DeliveryAddressPresentation,
	|	DisposalTable.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	DisposalTable.Comment AS Comment,
	|	DisposalTable.Currency AS Currency,
	|	DisposalTable.PaymentMethod AS PaymentMethod,
	|	DisposalTable.ContactPersonPresentation AS ContactPersonPresentation,
	|	TableForPayment.AmountToPay + TableForPayment.AmountToBePaidCourier AS AmountToPay
	|FROM
	|	TemporaryDisposalTable AS DisposalTable
	|		LEFT JOIN TemporaryTableForPayment AS TableForPayment
	|		ON DisposalTable.ReferenceOrder = TableForPayment.ReferenceOrder
	|ORDER BY
	|	CurrentOrder DESC,
	|	DeliveryDate,
	|	DeliveryTimeTo";
	
	Query.SetParameter("CurrentOrder", CurrentOrder);
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Statuses", WarehousesServer.StatusesOfOrdersDeliveredByCourier());
	
	Result = Query.Execute();
	
	SamplingByOrders = Result.Select();
	
	ListOfOrdersCurrent.Clear();
	TheListOfOrdersIsAsFollows.Clear();
	
	ThisIsCur = True;
	While SamplingByOrders.Next() Do
		
		If ThisIsCur Then
			NewRow = ListOfOrdersCurrent.Add();
			ThisIsCur = False;
			Items.ListOfOrdersCurrent.CurrentRow = NewRow.GetID();
			Items.GroupBasementOfTheCurrentList.Visible = SamplingByOrders.Comment <> "";
		Else
			NewRow = TheListOfOrdersIsAsFollows.Add();
			
			If SamplingByOrders.Comment <> "" Then
				NewRow.CommentPicture_2 = 1;
			EndIf;
			
		EndIf;
		
		FillPropertyValues(NewRow, SamplingByOrders);
		
		Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
		
		NewRow.DateTimeOfDeliveryPresentation = Module.DateTimeOfDeliveryPresentation(NewRow);
		NewRow.ThereIsStillTimeForDelivery = Module.ThereIsStillTimeForDelivery(NewRow);
		NewRow.SumPresentation = Module.AmountToPayPresentation(NewRow);
		NewRow.PaymentMethodPresentation = Module.PaymentMethodPresentation(NewRow);
		
	EndDo;
	
	TheNumberOfOrdersIsAsFollows = TheListOfOrdersIsAsFollows.Count();
	
EndProcedure

&AtClient
Procedure ShowMap(Data)
 
#If MobileClient Then
	ListOfLocations = New ValueList;
	ListOfLocations.Add(GetClientCoordinates(Data)); 
	ShowOnMap(ListOfLocations);
 #EndIf
	 
 EndProcedure

&AtClient
Function GetClientCoordinates(Data)
	
	Coordinates = New Structure();
	
#If MobileClient Then
		
	Coordinates = Undefined;
	AddressDataStructure = New Structure();
	AddressDataStructure.Insert("Presentation", Data.DeliveryAddressPresentation);
	
	AddressData = New AddressData(AddressDataStructure);
	Coordinates = GetLocationByAddress(AddressData);
 #EndIf
	 
	Return Coordinates;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfOrdersCurrentComment.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfOrdersCurrent.Comment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", "<not specified>");
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorAdditionalAssemblyAndDelivery);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfOrdersCurrentThereIsStillTimeForDelivery.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfOrdersCurrent.LateArrival");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.NegativeValuesTextColor);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheListOfOrdersIsAsFollowsThereIsStillTimeForDelivery.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheListOfOrdersIsAsFollows.LateArrival");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.NegativeValuesTextColor);
	
EndProcedure

#EndRegion
