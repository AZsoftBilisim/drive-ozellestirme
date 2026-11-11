#Region Internal

// Available types of alerts.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - CatalogRef.MetadataObjectIDs
//   * Value - Array of CatalogRef.UserNotificationKinds
Function AvailableNotificationKinds() Export
	
	AvailableNotificationKindsByType = New Map;
	
	Query = New Query;
	Query.Text = "SELECT DISTINCT
	|	UserNotificationKindsDataSources.SourceType AS SourceType,
	|	UserNotificationKindsDataSources.SourceDetails_ AS SourceDetails_,
	|	UserNotificationKindsDataSources.Ref AS NotificationKind
	|FROM
	|	Catalog.UserNotificationKinds.DataSources AS UserNotificationKindsDataSources
	|		INNER JOIN Catalog.UserNotificationKinds AS UserNotificationKinds
	|		ON UserNotificationKindsDataSources.Ref = UserNotificationKinds.Ref
	|WHERE
	|	UserNotificationKinds.Running = TRUE
	|	AND UserNotificationKinds.IsFolder = FALSE
	|	AND UserNotificationKinds.DeletionMark = FALSE
	|	AND UserNotificationKinds.NotificationType = VALUE(Enum.UserNotificationTypes.Nonexclusive)
	|TOTALS BY
	|	SourceType";
	QueryResult = Query.Execute();
	SelectionType = QueryResult.Select(QueryResultIteration.ByGroups);
	While SelectionType.Next() Do
		SamplingTypes = SelectionType.Select();
		ArrayOfViews = New Array;
		While SamplingTypes.Next() Do
			SourceDetails_ = ?(SamplingTypes.SourceDetails_ = "", "Ref", SamplingTypes.SourceDetails_);
			
			StructureTypeOfNotification = New Structure();
			StructureTypeOfNotification.Insert("NotificationKind", SamplingTypes.NotificationKind);
			StructureTypeOfNotification.Insert("SourceDetails_", SourceDetails_);
			
			ArrayOfViews.Add(StructureTypeOfNotification);
		EndDo;
		AvailableNotificationKindsByType.Insert(SelectionType.SourceType, ArrayOfViews);
	EndDo;
	
	Return AvailableNotificationKindsByType
	
EndFunction

// The user ID is the author of the alerts.
// 
// Parameters:
//  Author - CatalogRef.Users, Undefined - Author of alerts
// 
// Returns:
//  UUID - User Id Author Of Alerts
Function UserIsNotificationAuthor(Author = Undefined) Export
	If Not ValueIsFilled(Author) Then
		Author = UserNotificationsOfEventsCached.UserNotificationAuthor();
	EndIf;
	
	Return Common.ObjectAttributeValue(Author, "IBUserID");
	
EndFunction

// The user ID of the interaction system for the author of alerts.
// 
// Parameters:
//  Author - Undefined, CatalogRef.Users - Author
// 
// Returns:
//  CollaborationSystemUser, CollaborationSystemUserID - User Id Of The Interaction System Author Of Alerts
Function CollaborationSystemUserIDNotificationsAuthor(Author = Undefined) Export
	If Not ValueIsFilled(Author) Then
		Author = UserNotificationsOfEventsCached.UserNotificationAuthor();
	EndIf;
	
	UserIdentificator = Conversations.CollaborationSystemUser(Author, True);
	Return UserIdentificator;
EndFunction

// The user's language code.
// 
// Parameters:
//  IBUserID - String - The infobase user ID is a string.
// 
// Returns:
//  String - User Language Code
Function UserLanguageCode(Val IBUserID) Export
	
	LanguageCode = Common.DefaultLanguageCode();
	If ValueIsFilled(IBUserID)
		And TypeOf(IBUserID) <> Type("UUID") Then
		
		IBUserID = New UUID(IBUserID);
	EndIf;
	
	IBUserProperies = Users.IBUserProperies(IBUserID);
	If IBUserProperies <> Undefined And ValueIsFilled(IBUserProperies.Language) Then
		Language = Metadata.Languages.Find(IBUserProperies.Language);
		LanguageCode = Language.LanguageCode;
	EndIf;
	
	Return LanguageCode
	
EndFunction

// Sources of exception alerts.
// 
// Returns:
//  Array of String - Sources of Alerts Exceptions
Function SourcesOfNotificationExceptions() Export
	
	Return UserNotificationsOfEvents.SourcesOfNotificationExceptions();
	
EndFunction

// Author of user alerts.
// 
// Returns:
//  CatalogRef.Users - Author of User Alerts
Function UserNotificationAuthor() Export
	
	Author = Constants.UserNotificationAuthor.Get();
	UserNotificationsOfEventsOverridable.OnGettingUserNotificationAuthor(Author);
	
	If Not ValueIsFilled(Author) Then
		Author = UserNotificationsOfEvents.InternalUser();
		Constants.UserNotificationAuthor.Set(Author);
	EndIf;
	
	Return Author
EndFunction

#EndRegion