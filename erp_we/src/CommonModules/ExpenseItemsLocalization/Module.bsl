#Region Internal

#Region ObjectEventHandlers

// Called from the corresponding handler for the feature types plan
//
// Parameters:
//  Object - ChartOfCharacteristicTypesObject.ExpenseItems - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array of String - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	If Object.IsFolder Then
		Return;
	EndIf;
	
	
EndProcedure

// Called from the corresponding handler for the feature types plan
//
// Parameters:
//  Object - ChartOfCharacteristicTypesObject.ExpenseItems - processed object
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding handler for the feature types plan
//
// Parameters:
//  Object - ChartOfCharacteristicTypesObject.ExpenseItems - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure BeforeWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding handler for the feature types plan
//
// Parameters:
//  Object - ChartOfCharacteristicTypesObject.ExpenseItems - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
EndProcedure

#EndRegion

#Region MethodsOfManagerModule

// Complements the array of blocked object Attributes (See ChartsOfCharacteristicTypes.ExpenseItems.GetObjectAttributesToLock)
// .
//
// Parameters:
// 	AttributesToLock - Array of String  - The locking details of the object
// 	WithoutFormElements - Boolean - Add only details to the array, without form control elements.
//
Procedure AddBlockedItemDetails(AttributesToLock, WithoutFormElements = False) Export
EndProcedure

// Adds to the list of predefined expense items that are not available for selection
//
// Parameters:
// 	BlockedArticles - Array of ChartOfCharacteristicTypesRef.ExpenseItems - Links to unavailable items of expenditure 
//
Procedure AddBlockedArticlesToYourList(BlockedArticles) Export

EndProcedure

// Fills in the details of the expense account settings that affect the setup
// 	with the corresponding names of the accounting Analytics details.
//
// Parameters:
// 	MatchingNames - Map of KeyAndValue- the key is the name of the account that is used in setting up accounting accounts
// 		. the value is the corresponding name of the accounting Analytics account.
// 
Procedure FillInMatchingAccountSettingsDetails(MatchingNames) Export
	
	
EndProcedure

Procedure OnInitialItemFilling(Item) Export
	
	
EndProcedure

#EndRegion

#Region FormEventHandlers

// Called from the corresponding handler of the plan form for types of characteristics
//
// Parameters:
// 	Form - ClientApplicationForm - Form of the plan of types of characteristics
//
Procedure OnReadCreateAtServer(Form) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

Procedure ExpenseTypeCategoryOnChange(Form) Export
	
	
EndProcedure

Procedure ValueTypeOnChangeServer(Form) Export
EndProcedure

Procedure CostAllocationOptionLocalOnChangeServer(Form) Export
EndProcedure

Procedure CostAllocationOptionLocalOnChange(Form) Export
EndProcedure

// Called from the corresponding object form handler
//
// Parameters:
// 	TagName - String - Control name
// 	Form - ClientApplicationForm - Form of the plan of types of characteristics
//
Procedure OnChangeAttribute(TagName, Form) Export
EndProcedure

// Called from the corresponding object form handler
//
// Parameters:
// 	CommandName - String - Command name
// 	Form - ClientApplicationForm - Form of the plan of types of characteristics
//
Procedure ExecuteCommand(CommandName, Form) Export
	Return;
EndProcedure

#EndRegion

#Region Other

// Adds a description of production objects to the list of types of Analytics 2.1
//
// Parameters:
// 	TypesList - ValueList of String - List of types of analytics:
// 		* Value - String - String description of the type (for Example, " document Link.Custom production")
// 		* Presentation - String - Representation of the type to display on the form.
//
Procedure SupplementListOfTypesWithProductionAnalysts21(TypesList) Export
EndProcedure

// Adds a description of payroll accounting to the list of Analytics types
//
// Parameters:
// 	TypesList - ValueList of String - List of types of analytics:
// 		* Value - String - String description of the type (for Example, " enum Link.Videoarticle")
// 		* Presentation - String - Representation of the type to display on the form.
//
Procedure AddSalaryAccountingAnalystsToListOfTypes(TypesList) Export
EndProcedure

// Complements the list of cost analyst types to select for the "Value Formation" type of expenses.
//
// Parameters:
// 	ChoiceList - ValueList of String - List of types of analytics:
// 		* Value - String - String description of the type (for Example, " enum Link.Videoarticle")
// 		* Presentation - String - Representation of the type to display on the form.
//
Procedure CompleteSelectionListFormationOfVNACost(ChoiceList) Export
EndProcedure
#EndRegion

#EndRegion

