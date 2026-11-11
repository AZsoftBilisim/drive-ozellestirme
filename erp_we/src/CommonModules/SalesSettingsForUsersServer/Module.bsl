
#Region Public

// To clean up unused rules sales.
//
// Parameters:
//  Object - CatalogObject.SalesSettingsForUsers, CatalogObject.TermsOfSale - Object.
//
Procedure ClearUnusedSalesRules(Object) Export
	
	If Not Object.LimitDiscountAdjustments Then
		Object.PercentRateOfManualDiscount = 0;
		Object.MaximumPercentageForManualMarkup = 0;
		
		If TypeOf(Object) <> Type("CatalogObject.SalesSettingsForUsers") Then
			ArrayOfRowsToDelete_ = New Array();
			For Each TSRow In Object.PriceGroups Do
				TSRow.PercentRateOfManualDiscount  = 0;
				TSRow.MaximumPercentageForManualMarkup = 0;
				If TSRow.PricesKind.IsEmpty() Then
					ArrayOfRowsToDelete_.Add(TSRow);
				EndIf;
			EndDo;
			For Each Item In ArrayOfRowsToDelete_ Do
				Object.PriceGroups.Delete(Item);
			EndDo;
		Else
			Object.PriceGroups.Clear();
		EndIf;
		
	EndIf;
	
EndProcedure

// Get restrictions on discounts (mark-UPS)
//
// Parameters:
//  CustomerTermsOfSales - CatalogRef.TermsOfSale - Terms
//  User - CatalogRef.Users - user.
// 
// Returns:
//  ValueTable - Restrictions on discounts (margins).
//
Function RestrictionsOnDiscountsMargins(CustomerTermsOfSales = Undefined, User) Export

	SetPrivilegedMode(True);
	
	UseManualDiscounts                     = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UsePriceGroups                    = GetFunctionalOption("UsePriceGroups");
	UseManualDiscountRestrictionsInSales = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByUsers");
	
	If ValueIsFilled(CustomerTermsOfSales) Then
		UseRestrictionsOnAgreements         = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales");
	Else
		UseRestrictionsOnAgreements = False;
	EndIf;

	LimitDiscountAdjustments                     = UseManualDiscounts And (UseManualDiscountRestrictionsInSales Or UseRestrictionsOnAgreements);

	ChecksArray = New Array;

	If LimitDiscountAdjustments Then
		If UseManualDiscountRestrictionsInSales Then
			ChecksArray.Add("TemporaryTableLimitingManualDiscountsForAUserGroup");
			ChecksArray.Add("TemporaryTableManualDiscountRestrictionsUserGroupRestrictions");
			ChecksArray.Add("TemporaryTableManualDiscountRestrictionsGroupAndUserRestrictions");
		EndIf;
		ChecksArray.Add("TemporaryTableLimitationOfManualDiscountsGeneralRestrictions");
		ChecksArray.Add("TemporaryTableLimitingManualDiscounts");
		ChecksArray.Add("LimitationsOfManualDiscountsMarkups");
	Else
		Return Undefined;
	EndIf;

	QueryText = "";
	
	For Each CurItem In ChecksArray Do

		If  CurItem = "TemporaryTableLimitingManualDiscountsForAUserGroup" Then
			
			CreateQueryTemporaryTableLimitingManualDiscountsUserGroups(QueryText);
			
		ElsIf  CurItem = "TemporaryTableManualDiscountRestrictionsUserGroupRestrictions" Then
			
			CreateQueryTemporaryTableRestrictionOfManualDiscountsRestrictionsOnUserGroups(QueryText, UsePriceGroups);
			
		ElsIf  CurItem = "TemporaryTableManualDiscountRestrictionsGroupAndUserRestrictions" Then
			
			CreateTemporaryTableQueryLimitingManualDiscountsRestrictionsOnGroupsAndUsers(QueryText, UsePriceGroups);
			
		ElsIf  CurItem = "TemporaryTableLimitationOfManualDiscountsGeneralRestrictions" Then
			
			CreateQueryTemporaryTableManualDiscountRestrictionGeneralRestrictions(QueryText, UsePriceGroups, UseManualDiscountRestrictionsInSales, UseRestrictionsOnAgreements);
			
		ElsIf  CurItem = "TemporaryTableLimitingManualDiscounts" Then
			
			CreateRequestTemporaryTableLimitingManualDiscounts(QueryText);
			
		ElsIf CurItem = "LimitationsOfManualDiscountsMarkups" Then
			
			GenerateRequestLimitingManualDiscountsMarkups(QueryText);
			
		EndIf;

	EndDo;

	Query = New Query(QueryText);
	Query.SetParameter("User", User);
	If UseRestrictionsOnAgreements Then
		Query.SetParameter("CustomerTermsOfSales", CustomerTermsOfSales);
	EndIf;
	
	GroupOfUsersWithSalesSettings = GetUserSGroupWithSalesSettingsForUser(
		User, 
		"DiscountsMarkups"
	);
	Query.SetParameter("UsersGroup", GroupOfUsersWithSalesSettings);
	
	Return Query.Execute().Unload();

EndFunction

// Generate a temporary table query limiting manual discounts for a group of users.
//
// Parameters:
//  QueryText - String - query text.
//
Procedure CreateQueryTemporaryTableLimitingManualDiscountsUserGroups(QueryText) Export
	
	QueryText = QueryText + "
	|SELECT DISTINCT
	|	UserGroupsComposition.Ref AS Ref
	|INTO TemporaryTableLimitingManualDiscountsForAUserGroup
	|FROM
	|	Catalog.UserGroups.Content AS UserGroupsComposition
	|WHERE
	|	UserGroupsComposition.Ref = &UsersGroup
	|;
	|";
	
EndProcedure

// Generate a query temporary table manual discount restrictions restrictions on user groups.
//
// Parameters:
//  QueryText - String - Query text
//  UsePriceGroups - Boolean - Indicates whether price groups are used.
//
Procedure CreateQueryTemporaryTableRestrictionOfManualDiscountsRestrictionsOnUserGroups(QueryText, UsePriceGroups) Export
	
	QueryTextArray = New Array();
	
	QueryTextRestrictions = "
	|SELECT
	|	TemporaryTableLimitingManualDiscountsForAUserGroup.Ref AS UsersGroup,
	|	VALUE(Catalog.PriceGroups.EmptyRef)                   AS PriceGroup,
	|	SalesSettingsForUsers.PercentRateOfManualDiscount               AS PercentRateOfManualDiscount,
	|	SalesSettingsForUsers.MaximumPercentageForManualMarkup              AS MaximumPercentageForManualMarkup
	|INTO TemporaryTableManualDiscountRestrictionsUserGroupRestrictions
	|FROM
	|	TemporaryTableLimitingManualDiscountsForAUserGroup AS TemporaryTableLimitingManualDiscountsForAUserGroup
	|		INNER JOIN Catalog.SalesSettingsForUsers AS SalesSettingsForUsers
	|		ON TemporaryTableLimitingManualDiscountsForAUserGroup.Ref = SalesSettingsForUsers.Owner
	|		AND SalesSettingsForUsers.LimitDiscountAdjustments
	|";
	QueryTextArray.Add(QueryTextRestrictions);
	
	If UsePriceGroups Then
		
		QueryTextRestrictions = "
		|SELECT
		|	TemporaryTableLimitingManualDiscountsForAUserGroup.Ref AS UsersGroup,
		|	SalesSettingsForUsersPriceGroups.PriceGroup        AS PriceGroup,
		|	SalesSettingsForUsersPriceGroups.PercentRateOfManualDiscount  AS PercentRateOfManualDiscount,
		|	SalesSettingsForUsersPriceGroups.MaximumPercentageForManualMarkup AS MaximumPercentageForManualMarkup
		|FROM
		|	TemporaryTableLimitingManualDiscountsForAUserGroup AS TemporaryTableLimitingManualDiscountsForAUserGroup
		|		INNER JOIN Catalog.SalesSettingsForUsers.PriceGroups AS SalesSettingsForUsersPriceGroups
		|		ON TemporaryTableLimitingManualDiscountsForAUserGroup.Ref = SalesSettingsForUsersPriceGroups.Ref.Owner
		|		AND SalesSettingsForUsersPriceGroups.Ref.LimitDiscountAdjustments
		|";
		
		QueryTextArray.Add(QueryTextRestrictions);
		
	EndIf;
	
	QueryTextSeparator = "
	|UNION ALL
	|";
	
	FullTextOfRestrictionRequest = StrConcat(QueryTextArray, QueryTextSeparator);
	
	QueryText = QueryText + FullTextOfRestrictionRequest + "
	|;";
	
EndProcedure

// Generate a query temporary table manual discount restrictions restrictions on groups and users.
//
// Parameters:
//  QueryText - String - Query text
//  UsePriceGroups - Boolean - Indicates whether price groups are used.
//
Procedure CreateTemporaryTableQueryLimitingManualDiscountsRestrictionsOnGroupsAndUsers(QueryText, UsePriceGroups) Export
	
	QueryTextArray = New Array();
	
	RestrictionRequestText = "
	|SELECT
	|	2                                                                                                       AS Priority,
	|	TemporaryTableManualDiscountRestrictionsUserGroupRestrictions.PriceGroup                  AS PriceGroup,
	|	MAX(TemporaryTableManualDiscountRestrictionsUserGroupRestrictions.PercentRateOfManualDiscount)  AS PercentRateOfManualDiscount,
	|	MAX(TemporaryTableManualDiscountRestrictionsUserGroupRestrictions.MaximumPercentageForManualMarkup) AS MaximumPercentageForManualMarkup
	|INTO TemporaryTableManualDiscountRestrictionsGroupAndUserRestrictions
	|FROM
	|	TemporaryTableManualDiscountRestrictionsUserGroupRestrictions AS TemporaryTableManualDiscountRestrictionsUserGroupRestrictions
	|
	|GROUP BY
	|	TemporaryTableManualDiscountRestrictionsUserGroupRestrictions.PriceGroup
	|
	|UNION ALL
	|
	|SELECT
	|	1                                                    AS Priority,
	|	VALUE(Catalog.PriceGroups.EmptyRef)      AS PriceGroup,
	|	SalesSettingsForUsers.PercentRateOfManualDiscount  AS PercentRateOfManualDiscount,
	|	SalesSettingsForUsers.MaximumPercentageForManualMarkup AS MaximumPercentageForManualMarkup
	|FROM
	|	Catalog.SalesSettingsForUsers AS SalesSettingsForUsers
	|WHERE
	|	SalesSettingsForUsers.Owner = &User
	|	AND SalesSettingsForUsers.LimitDiscountAdjustments
	|";
	QueryTextArray.Add(RestrictionRequestText);
	
	If UsePriceGroups Then
		
		RestrictionRequestText = "
		|SELECT
		|	1                                                                 AS Priority,
		|	SalesSettingsForUsersPriceGroups.PriceGroup AS    PriceGroup,
		|	SalesSettingsForUsersPriceGroups.PercentRateOfManualDiscount  AS PercentRateOfManualDiscount,
		|	SalesSettingsForUsersPriceGroups.MaximumPercentageForManualMarkup AS MaximumPercentageForManualMarkup
		|FROM
		|	Catalog.SalesSettingsForUsers.PriceGroups AS SalesSettingsForUsersPriceGroups
		|WHERE
		|	SalesSettingsForUsersPriceGroups.Ref.Owner = &User
		|	AND SalesSettingsForUsersPriceGroups.Ref.LimitDiscountAdjustments
		|";
		QueryTextArray.Add(RestrictionRequestText);
		
	EndIf;
	
	QueryTextSeparator = "
	|UNION ALL
	|";
	
	FullTextOfRestrictionRequest = StrConcat(QueryTextArray, QueryTextSeparator);
	
	QueryText = QueryText + FullTextOfRestrictionRequest + "
	|;";
	
EndProcedure

// Generate a query temporary table manual discount restrictions General restrictions.
//
// Parameters:
//  QueryText - String - Query text
//  UsePriceGroups - Boolean - Indicates whether price groups are used.
//  UseUserRestrictions - Boolean - Indicates whether user restrictions are being used.
//  UseRestrictionsOnAgreements - Boolean - Signs of use restrictions under the agreements.
//
Procedure CreateQueryTemporaryTableManualDiscountRestrictionGeneralRestrictions(QueryText, UsePriceGroups, UseUserRestrictions, UseRestrictionsOnAgreements) Export
	
	QueryTextArray = New Array();
	
	TempTableName = "TemporaryTableLimitationOfManualDiscountsGeneralRestrictions";
	If UseUserRestrictions Then
		
		RestrictionRequestText =  "
		|SELECT
		|	PriceGroups.Ref AS Ref,
		|	0.00                 AS PercentRateOfManualDiscount,
		|	0.00                 AS MaximumPercentageForManualMarkup
		|INTO PriceGroups
		|FROM
		|	Catalog.PriceGroups AS PriceGroups
		|	
		|UNION ALL
		|			
		|SELECT
		|	VALUE(Catalog.PriceGroups.EmptyRef),
		|	0.00 AS PercentRateOfManualDiscount,
		|	0.00 AS MaximumPercentageForManualMarkup
		|;
		|
		|///////////////////////////////////////////////////////////
		|SELECT
		|	MIN(TemporaryTableManualDiscountRestrictionsGroupAndUserRestrictions.Priority) AS Priority,
		|	TemporaryTableManualDiscountRestrictionsGroupAndUserRestrictions.PriceGroup      AS PriceGroup
		|INTO LimitingManualDiscountsByGroupsAndUsers
		|FROM
		|	TemporaryTableManualDiscountRestrictionsGroupAndUserRestrictions AS TemporaryTableManualDiscountRestrictionsGroupAndUserRestrictions
		|	
		|GROUP BY
		|	TemporaryTableManualDiscountRestrictionsGroupAndUserRestrictions.PriceGroup
		|;
		|
		|///////////////////////////////////////////////////////////
		|SELECT 
		|	Table.PriceGroup                  AS PriceGroup,
		|	MAX(Table.PercentRateOfManualDiscount)  AS PercentRateOfManualDiscount,
		|	MAX(Table.MaximumPercentageForManualMarkup) AS MaximumPercentageForManualMarkup
		|INTO TableOfConstraints
		|FROM
		|	(SELECT
		|		Restrictions.PriceGroup        AS PriceGroup,
		|		Restrictions.PercentRateOfManualDiscount  AS PercentRateOfManualDiscount,
		|		Restrictions.MaximumPercentageForManualMarkup AS MaximumPercentageForManualMarkup
		|	FROM
		|		LimitingManualDiscountsByGroupsAndUsers
		|		LEFT JOIN TemporaryTableManualDiscountRestrictionsGroupAndUserRestrictions AS Restrictions
		|		ON (Restrictions.PriceGroup = LimitingManualDiscountsByGroupsAndUsers.PriceGroup)
		|			AND (Restrictions.Priority = LimitingManualDiscountsByGroupsAndUsers.Priority)
		|	) AS Table
		|
		|GROUP BY
		|	Table.PriceGroup
		|;
		|
		|///////////////////////////////////////////////////////////
		|SELECT
		|	PriceGroups.Ref                                                                        AS PriceGroup,
		|	ISNULL(TableOfConstraints.PercentRateOfManualDiscount,  TableOfConstraints0.PercentRateOfManualDiscount)  AS PercentRateOfManualDiscount,
		|	ISNULL(TableOfConstraints.MaximumPercentageForManualMarkup, TableOfConstraints0.MaximumPercentageForManualMarkup) AS MaximumPercentageForManualMarkup
		|INTO TempTableName
		|FROM PriceGroups
		|LEFT JOIN TableOfConstraints
		|ON TableOfConstraints.PriceGroup = PriceGroups.Ref 
		|
		|LEFT JOIN TableOfConstraints AS TableOfConstraints0
		|ON TableOfConstraints0.PriceGroup = VALUE(Catalog.PriceGroups.EmptyRef)";
		
		RestrictionRequestText = StrReplace(RestrictionRequestText, "TempTableName", TempTableName);
		QueryTextArray.Add(RestrictionRequestText);
		
	EndIf;
	
	If UseRestrictionsOnAgreements Then
		
		RestrictionRequestText = "
		|SELECT
		|	VALUE(Catalog.PriceGroups.EmptyRef) AS PriceGroup,
		|	TermsOfSale.PercentRateOfManualDiscount        AS PercentRateOfManualDiscount,
		|	TermsOfSale.MaximumPercentageForManualMarkup       AS MaximumPercentageForManualMarkup
		|INTO TempTableName
		|FROM
		|	Catalog.TermsOfSale AS TermsOfSale
		|WHERE
		|	TermsOfSale.Ref = &CustomerTermsOfSales
		|	AND TermsOfSale.LimitDiscountAdjustments
		|";
		
		If Not UseUserRestrictions Then
			RestrictionRequestText = StrReplace(RestrictionRequestText, "TempTableName", TempTableName);			
		Else
			RestrictionRequestText = StrReplace(RestrictionRequestText, "INTO TempTableName", "");
		EndIf;
		
		QueryTextArray.Add(RestrictionRequestText);
		
		If UsePriceGroups Then
			
			RestrictionRequestText = "
			|SELECT
			|	CatalogPriceGroups.Ref                  AS PriceGroup,
			|	TermsOfSale.PercentRateOfManualDiscount        AS PercentRateOfManualDiscount,
			|	TermsOfSale.MaximumPercentageForManualMarkup       AS MaximumPercentageForManualMarkup
			|FROM
			|	Catalog.TermsOfSale AS TermsOfSale
			|		LEFT JOIN Catalog.PriceGroups AS CatalogPriceGroups ON TRUE
			|WHERE
			|	TermsOfSale.Ref = &CustomerTermsOfSales
			|	AND CatalogPriceGroups.Ref NOT IN (SELECT T.PriceGroup FROM Catalog.TermsOfSale.PriceGroups AS T WHERE T.Ref = &CustomerTermsOfSales AND T.Ref.LimitDiscountAdjustments)
			|	AND TermsOfSale.LimitDiscountAdjustments
			|
			|UNION ALL
			|
			|SELECT
			|	TermsOfSalePriceGroups.PriceGroup        AS PriceGroup,
			|	TermsOfSalePriceGroups.PercentRateOfManualDiscount  AS PercentRateOfManualDiscount,
			|	TermsOfSalePriceGroups.MaximumPercentageForManualMarkup AS MaximumPercentageForManualMarkup
			|FROM
			|	Catalog.TermsOfSale.PriceGroups AS TermsOfSalePriceGroups
			|WHERE
			|	TermsOfSalePriceGroups.Ref = &CustomerTermsOfSales
			|	AND TermsOfSalePriceGroups.Ref.LimitDiscountAdjustments
			|";
			QueryTextArray.Add(RestrictionRequestText);
			
		EndIf;
		
	EndIf;
	
	If QueryTextArray.Count() Then 
		
		QueryTextSeparator = "
		|UNION ALL
		|";
		
		FullTextOfRestrictionRequest = StrConcat(QueryTextArray, QueryTextSeparator);
		
		QueryText = QueryText + FullTextOfRestrictionRequest + "
		|;";
		
	EndIf;
	
EndProcedure

// Generate the query temporary table of manual discount restrictions.
//
// Parameters:
//  QueryText - String - query text.
//
Procedure CreateRequestTemporaryTableLimitingManualDiscounts(QueryText) Export
	
	QueryText = QueryText + "
	|SELECT
	|	TemporaryTableLimitationOfManualDiscountsGeneralRestrictions.PriceGroup,
	|	MIN(TemporaryTableLimitationOfManualDiscountsGeneralRestrictions.MaximumPercentageForManualMarkup) AS MaximumPercentageForManualMarkup,
	|	MIN(TemporaryTableLimitationOfManualDiscountsGeneralRestrictions.PercentRateOfManualDiscount) AS PercentRateOfManualDiscount
	|INTO TemporaryTableLimitingManualDiscounts
	|FROM
	|	TemporaryTableLimitationOfManualDiscountsGeneralRestrictions AS TemporaryTableLimitationOfManualDiscountsGeneralRestrictions
	|
	|GROUP BY
	|	TemporaryTableLimitationOfManualDiscountsGeneralRestrictions.PriceGroup
	|;
	|";
	
EndProcedure

// Get RMK access rights for the user.
//
// Parameters:
//  User - CatalogRef - user.
// 
// Returns:
//  Structure - User access rights.
//
Function CWPAccessRights(User) Export
	
	SetPrivilegedMode(True);
	
	AccessRights = DefaultAccessRights();
	
	Query = New Query(
	"SELECT
	|	2 AS Priority,
	|	SalesSettingsForUsers.Ref AS Ref,
	|	SalesSettingsForUsers.CWP_Delay AS Snooze,
	|	SalesSettingsForUsers.CWP_Reserve AS Reserve_,
	|	SalesSettingsForUsers.CWP_CashWithdrawal AS WithdrawalOfMoney,
	|	SalesSettingsForUsers.CWP_CashDeposit AS DepositingMoney,
	|	SalesSettingsForUsers.CWP_OpenShift AS OpenShift,
	|	SalesSettingsForUsers.CWP_CloseShift AS CloseShift,
	|	SalesSettingsForUsers.CWP_ReturnOfGoods AS GoodsReturn,
	|	SalesSettingsForUsers.RowAdjustment AS LineAdjustment,
	|	SalesSettingsForUsers.CWP_ManualChangeOfLoyaltyCard AS ChangingLoyaltyCards,
	|	SalesSettingsForUsers.CWP_ChangeLoyaltyCardHolderInformation AS EditingCustomerInformation,
	|	SalesSettingsForUsers.RMK_AllowPaymentWithoutConfirmationFromSBP AS AllowPaymentWithoutConfirmationFromSBP,
	|	SalesSettingsForUsers.CWP_AllowPriceChangesWhenReturningWithoutReceipt AS AllowPriceChangesWhenReturningWithoutReceipt
	|
	|INTO Settings
	|FROM
	|	(SELECT DISTINCT
	|		T.Ref AS Ref
	|	FROM
	|		Catalog.UserGroups.Content AS T
	|	WHERE
	|		T.Ref = &UsersGroup) AS UserGroups
	|		LEFT JOIN Catalog.SalesSettingsForUsers AS SalesSettingsForUsers
	|		ON UserGroups.Ref = SalesSettingsForUsers.Owner
	|WHERE
	|	SalesSettingsForUsers.CWP_Use
	|
	|UNION ALL
	|
	|SELECT
	|	1,
	|	SalesSettingsForUsers.Ref,
	|	SalesSettingsForUsers.CWP_Delay,
	|	SalesSettingsForUsers.CWP_Reserve,
	|	SalesSettingsForUsers.CWP_CashWithdrawal,
	|	SalesSettingsForUsers.CWP_CashDeposit,
	|	SalesSettingsForUsers.CWP_OpenShift,
	|	SalesSettingsForUsers.CWP_CloseShift,
	|	SalesSettingsForUsers.CWP_ReturnOfGoods,
	|	SalesSettingsForUsers.RowAdjustment,
	|	SalesSettingsForUsers.CWP_ManualChangeOfLoyaltyCard,
	|	SalesSettingsForUsers.CWP_ChangeLoyaltyCardHolderInformation,
	|	SalesSettingsForUsers.RMK_AllowPaymentWithoutConfirmationFromSBP,
	|	SalesSettingsForUsers.CWP_AllowPriceChangesWhenReturningWithoutReceipt
	|
	|FROM
	|	Catalog.SalesSettingsForUsers AS SalesSettingsForUsers
	|WHERE
	|	SalesSettingsForUsers.Owner = &User
	|	AND SalesSettingsForUsers.CWP_Use
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	Settings.Priority AS Priority,
	|	MAX(Settings.Snooze) AS Snooze,
	|	MAX(Settings.Reserve_) AS Reserve_,
	|	MAX(Settings.WithdrawalOfMoney) AS WithdrawalOfMoney,
	|	MAX(Settings.DepositingMoney) AS DepositingMoney,
	|	MAX(Settings.OpenShift) AS OpenShift,
	|	MAX(Settings.CloseShift) AS CloseShift,
	|	MAX(Settings.GoodsReturn) AS GoodsReturn,
	|	MAX(Settings.LineAdjustment) AS LineAdjustment,
	|	MAX(Settings.ChangingLoyaltyCards) AS ChangingLoyaltyCards,
	|	MAX(Settings.EditingCustomerInformation) AS EditingCustomerInformation,
	|	MAX(Settings.AllowPaymentWithoutConfirmationFromSBP) AS AllowPaymentWithoutConfirmationFromSBP,
	|	MAX(Settings.AllowPriceChangesWhenReturningWithoutReceipt) AS AllowPriceChangesWhenReturningWithoutReceipt
	|
	|FROM
	|	Settings AS Settings
	|
	|GROUP BY
	|	Settings.Priority
	|
	|ORDER BY
	|	Priority");
	
	Query.SetParameter("User", User);
	
	GroupOfUsersWithSalesSettings = GetUserSGroupWithSalesSettingsForUser(
		User,
		"CWPSettings"
	);
	Query.SetParameter("UsersGroup", GroupOfUsersWithSalesSettings);

	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		FillPropertyValues(AccessRights, Selection);
	EndIf;
	
	Return AccessRights;
	
EndFunction

#EndRegion

#Region Private

Procedure GenerateRequestLimitingManualDiscountsMarkups(QueryText)
	
	QueryText = QueryText + "
		|SELECT
		|	TemporaryTableLimitingManualDiscounts.PriceGroup        AS PriceGroup,
		|	TemporaryTableLimitingManualDiscounts.PercentRateOfManualDiscount  AS MaximumPercentageForManualDiscount,
		|	TemporaryTableLimitingManualDiscounts.MaximumPercentageForManualMarkup AS MaximumPercentageForManualMarkup
		|FROM
		|	TemporaryTableLimitingManualDiscounts AS TemporaryTableLimitingManualDiscounts
		|";
	
EndProcedure

Function DefaultAccessRights()

	ReturnValue = New Structure;
	
	DefaultValue = True;
	
	ReturnValue.Insert("Snooze",        DefaultValue);
	ReturnValue.Insert("Reserve_", DefaultValue);
	
	ReturnValue.Insert("WithdrawalOfMoney",   DefaultValue);
	ReturnValue.Insert("DepositingMoney", DefaultValue);
	
	ReturnValue.Insert("OpenShift", DefaultValue);
	ReturnValue.Insert("CloseShift", DefaultValue);
	
	ReturnValue.Insert("GoodsReturn", DefaultValue);
	
	ReturnValue.Insert("LineAdjustment",      DefaultValue);
	ReturnValue.Insert("ChangingLoyaltyCards", DefaultValue);
	ReturnValue.Insert("EditingCustomerInformation", DefaultValue);
	ReturnValue.Insert("AllowPaymentWithoutConfirmationFromSBP", DefaultValue);
	ReturnValue.Insert("AllowPriceChangesWhenReturningWithoutReceipt", DefaultValue);
	
	Return ReturnValue;
	
EndFunction

// Get the user's group with sales settings for the user.
//
// Parameters:
//  User - CatalogRef - user.
//  Mode - String - Restriction group selection mode (discount rates and Company settings).
// 
// Returns:
// CatalogRef.UserGroups - A group of users.
//
Function GetUserSGroupWithSalesSettingsForUser(User, Mode = "DiscountsMarkups") Export
	
	Result = Undefined;

	Query = New Query;
	Query.SetParameter("User", User);
	Query.Text =
	"SELECT
	|	GroupCompositionTable.Ref AS UsersGroup
	|FROM
	|	Catalog.UserGroups.Content AS GroupCompositionTable
	|WHERE
	|	GroupCompositionTable.User = &User
	|	AND NOT GroupCompositionTable.Ref.DeletionMark
	|TOTALS BY
	|	UsersGroup HIERARCHY";
	
	GroupsTree = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	GroupTableHierarchy = New ValueTable;
	GroupTableHierarchy.Columns.Add("UsersGroup", New TypeDescription("CatalogRef.UserGroups"));
	GroupTableHierarchy.Columns.Add("Priority", New TypeDescription("Number"));
	
	CreateTableOfUserGroupsRecursively(GroupsTree, GroupTableHierarchy, 1);
	
	If GroupTableHierarchy.Count() > 0 Then
		
		Query.SetParameter("GroupTableHierarchy", GroupTableHierarchy);
		Query.SetParameter("Mode", Mode);
		Query.Text =
		"SELECT
		|	CAST(TT.UsersGroup AS Catalog.UserGroups) AS UsersGroup,
		|	TT.Priority AS Priority
		|INTO GroupTableHierarchy
		|FROM
		|	&GroupTableHierarchy AS TT
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	GroupTableHierarchy.UsersGroup AS UsersGroup
		|FROM
		|	GroupTableHierarchy AS GroupTableHierarchy
		|		INNER JOIN Catalog.SalesSettingsForUsers AS TableOfSalesSettings
		|		ON GroupTableHierarchy.UsersGroup = TableOfSalesSettings.Owner
		|			AND (CASE
		|				WHEN &Mode = ""DiscountsMarkups""
		|					THEN TableOfSalesSettings.LimitDiscountAdjustments
		|				WHEN &Mode = ""CWPSettings""
		|					THEN TableOfSalesSettings.CWP_Use
		|				ELSE TableOfSalesSettings.LimitDiscountAdjustments
		|						AND TableOfSalesSettings.CWP_Use
		|			END)
		|
		|ORDER BY
		|	GroupTableHierarchy.Priority DESC,
		|	GroupTableHierarchy.UsersGroup.Description";
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Result = Selection.UsersGroup;
		EndIf;
		
	EndIf;
	
	Return Result;

EndFunction

// perform a recursive traversal of the hierarchy tree of the selected user groups
// and build a table of suitable user groups taking into account the priority
//
// Parameters:
//  GroupsTree - ValueTree - The hierarchy tree of user groups.
//  TableOfSalesSettings - ValueTable - An empty table of values to fill in.
//  Priority - Number - the priority of the top level of the tree.
// 
Procedure CreateTableOfUserGroupsRecursively(GroupsTree, TableOfSalesSettings, Priority)
	
	For Each TreeRow In GroupsTree.Rows Do
		
		If ValueIsFilled(TreeRow.Parent)
			And TreeRow.UsersGroup = TreeRow.Parent.UsersGroup Then
			Continue;
		EndIf;
		
		NewRow = TableOfSalesSettings.Add();
		NewRow.UsersGroup = TreeRow.UsersGroup;
		NewRow.Priority = Priority;
		
		CreateTableOfUserGroupsRecursively(TreeRow, TableOfSalesSettings, Priority + 1);
		
	EndDo;
	
EndProcedure

#EndRegion
