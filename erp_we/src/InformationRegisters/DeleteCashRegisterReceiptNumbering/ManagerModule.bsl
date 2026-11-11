#Region Public

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// StandardSubsystems.AccessManagement
// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
//
// Parameters:
//  Restriction - Structure:
//    * Text                             - String - restricting access for users.
//                                          If the string is empty, it means that access is allowed.
//    * TextForExternalUsers1      - String - restricting access for external users.
//                                          If the string is empty, it means that access is denied.
//    * ByOwnerWithoutSavingAccessKeys - Undefined - to determine automatically.
//                                        - Boolean - if False, then always write access keys,
//                                          if True, then do not write access keys,
//                                          but use the owner's access keys (it is required
//                                          that the restriction be strictly on the owner object).
//   * ByOwnerWithoutSavingAccessKeysForExternalUsers - Undefined, Boolean - the
//                                          same as for the parameter for the owner of the record of the key access.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
EndProcedure
// End StandardSubsystems.AccessManagement

#EndIf

#EndRegion