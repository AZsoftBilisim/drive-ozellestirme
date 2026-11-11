////////////////////////////////////////////////////////////////////////////////
// Overridable procedures called from form handlers, such as:
// "Joining the Server", "Joining the Server", "Before recording the Server", 
// "After recording", as well as when changing some of the details of the tabular part,
// such as "Nomenclature", "Characteristics".
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region FillingInFormHandlers

// An overridable procedure called from the form event handler of the same name.
//
// Parameters:
// 	Form - ClientApplicationForm - the form from which the procedure is called from the event handler.
// 	Cancel - Boolean -
// 	StandardProcessing - Boolean - 
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
EndProcedure

// An overridable procedure called from the form event handler of the same name.
//
// Parameters:
// 	Form - ClientApplicationForm - the form from which the procedure is called from the event handler.
// 	CurrentObject - DocumentObject, CatalogObject - 
//
Procedure OnReadAtServer(Form, CurrentObject) Export
	
EndProcedure

// An overridable procedure called from the form event handler of the same name.
//
// Parameters:
// 	Form - ClientApplicationForm - the form from which the procedure is called from the event handler.
// 	Cancel - Boolean - 
// 	CurrentObject - DocumentObject, CatalogObject - 
// 	WriteParameters - Structure - 
//
Procedure BeforeWriteAtServer(Form, Cancel, CurrentObject, WriteParameters)Export
	
EndProcedure

// An overridable procedure called from the form event handler of the same name.
//
// Parameters:
// 	Form - ClientApplicationForm - the form from which the procedure is called from the event handler.
// 	CurrentObject - DocumentObject, CatalogObject - 
// 	WriteParameters - Structure - 
//
Procedure AfterWriteAtServer(Form, CurrentObject, WriteParameters)Export
	
EndProcedure

#EndRegion

#Region FillingInProducts

// An overridden procedure that is called from the "Nomenclature" attribute handler in the table part.
//
// Parameters:
// 	CurrentRow - FormDataCollectionItem - current row of the table part.
// 	ActionParameters - Structure - valid actions for the table part.
//	CachedValues - Structure - Cached values of the table part.
Procedure ProductsOnChangeOverridable(CurrentRow, ActionParameters, CachedValues)Export


EndProcedure

#EndRegion 

#Region FillingInCharacteristics

// An overridden procedure that is called from the handler of the "Characteristic" attribute of the table part.
//
// Parameters:
// 	CurrentRow - FormDataCollectionItem - current row of the table part.
// 	ActionParameters - Structure - valid actions for the table part.
//	CachedValues - Structure - Cached values of the table part.
Procedure CharacteristicOnChangeOverridable(CurrentRow, ActionParameters, CachedValues)Export


EndProcedure
	
#EndRegion 

#Region MailoutsAndNotificationsToCustomers

// An overridden procedure that returns a flag indicating that the event type of the scheduled task needs to be configured.
//
// Parameters:
//  EventType  - EnumRef.NotificationEventTypes - the type of alert event that the attribute is specified for.
//
// Returns:
//   Boolean   - True if setting up a routine task is necessary, False in the opposite case.
//
Function EventTypeRequiresSettingUpRoutineTask(EventType) Export

	Return False;

EndFunction

// An overridable procedure in which you can configure parameters for processing the notification queue by event type.
//
// Parameters:
//  EventType         - EnumRef.NotificationEventTypes - the type of notification event for which the settings are specified.
//  SettingsStructure  - Structure - Settings, a detailed description can be found in the module of the manager of the enumeration of event types of announcements.
//
Procedure EventTypeSettingsForHandlingAlertQueue(EventType, SettingsStructure) Export

	

EndProcedure

// An overridable procedure in which you can configure data analysis for alerts to clients and write to the notification queue.
// For implementation examples, see in the general module for sending messages to clients.
//
// Parameters:
//  NotificationKind  - CatalogRef.CustomerNotificationKinds - the type of alert that data analysis is performed for.
//
Procedure DataAnalysisForAlertType(NotificationKind) Export

	

EndProcedure 

// An overridable procedure in which you can get the state of an object before writing.
//
// Parameters:
//  Source  - Arbitrary - the object or set of register entries that triggered the "before writing" event.
//  Cancel  - Boolean - indicates that the object was not recorded.
//  WriteMode  - DocumentWriteMode - valid only if the document is recorded, otherwise Undefined.
//  PostingMode  - DocumentPostingMode - it is valid only in the case of the document, in other cases it is Undefined.
//
Procedure NotificationSourceBeforeWrite(Source, Cancel, WriteMode , PostingMode) Export
	
	
	
EndProcedure

// An overridable procedure in which you can get the new state of an object and, if necessary, write
// to the notification queue.
//
// Parameters:
//  Source  - Arbitrary - the object or set of register entries that triggered the "on write" event.
//  Cancel  - Boolean - indicates that the object was not recorded.
//
Procedure SourceOfRecordingAlert(Source, Cancel) Export
	
	
	
EndProcedure 

#EndRegion

#EndRegion
