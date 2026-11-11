#Region Public

// See AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles
//
Procedure AddSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export
		
	IndexOfProfiles = IndexProfiles(ProfilesDetails, "Name");

EndProcedure

// Fills an array of structures that will be used for initial filling and
// restoring initial filling of profiles.
//
// See AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles
//
Procedure FillInSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export
		
	IndexProfiles(ProfilesDetails, "Name");
EndProcedure

// Fills in the list of access types used when restricting the rights of metadata objects.
// If the list of access types is not filled in, the access Rights report shows incorrect information.
//
// Only the access types used in the access restriction templates must be filled in
// explicitly, and the access types used in access value sets can be obtained from the current
// state of the access Value set information register.
//
// To automatically prepare the procedure content, use
// the developer tools for the access Control subsystem.
//
// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionKinds
// 
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export

	LongDesc = LongDesc + "

	|";

EndProcedure

// Fills in the use of access types depending on the functional configuration options,
// for example, use the access group of the Nomenclature.
// 
// Parameters:
//  AccessKind - String - type of access.
//  Use - Boolean - the value of the corresponding constants.
//
// See TMAccessManagement.OnFillAccessKindUsage
//
Procedure FillInUseOfAccessType(AccessKind, Use) Export

	
EndProcedure

// Allows you to override the restriction specified in the metadata object Manager module.
//
// Parameters:
//  List - MetadataObject - the list for which you want to return the text limit.
//                              In the procedure for populating the list with access Restrictions, you must
//                              specify the value False for the list, otherwise the call will not be made.
//
//  Restriction - Structure - with properties, as for procedures in manager modules. See properties
//                            in the comments to the procedure for filling in the access limit.
//
Procedure OnFillAccessRestriction(List, Restriction) Export
	
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessKinds
//
Procedure FillInAccessTypes(AccessKinds) Export
	
	
EndProcedure

// Allows you to specify lists where metadata objects contain a description
// of the access restriction logic in the Manager modules or the module being redefined.
//
// Parameters:
//  Lists - See AccessManagementOverridable.OnFillListsWithAccessRestriction
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
EndProcedure

// See SaaSOperationsCTLOverridable.SetAccessToThisDataArea
//
Procedure SetAccessToThisDataArea(User, AccessAllowed) Export


EndProcedure

#EndRegion

#Region Private

Function IndexProfiles(ProfilesDetails, ProfileField = "Name")
	
	Result = New Map;
	For IndexOf = 0 To ProfilesDetails.UBound() Do
		
		Profile = ProfilesDetails[IndexOf];
		Result.Insert(Profile[ProfileField], IndexOf);
		
	EndDo;
	Return Result;
	
EndFunction

// Utility function. Made export for ease of implementation.
//
Procedure AddRequiredRolesToYourProfile(ProfileDetails) Export
	
	
EndProcedure

Procedure AddSalesRepresentativeRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddNeedsManagerRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddFinancialAnalystRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddPurchasingManagerRoles(ProfileDetails) Export
	
	
EndProcedure

// Service function. Made export-friendly to avoid duplication.

// It is used when forming the MFP Accountant profile.

//
Procedure AddAccountantLocalAccountingRolesToRead(ProfileDetails) Export
	
	
EndProcedure

// Service function. Made export-friendly to avoid duplication.

// It is used when forming the MFP Accountant profile.

//
Procedure AddAccountantRolesLocalAccountingRolesForChange(ProfileDetails) Export
	
	
EndProcedure

Procedure AddSupervisorSalesRepRoles(ProfileDetails) Export
EndProcedure

Procedure AddMarketerRoles(ProfileDetails) Export
EndProcedure

Procedure AddSalesManagerRoles_(ProfileDetails) Export
EndProcedure

Procedure AddDeliveryManagerRoles(ProfileDetails) Export
EndProcedure

Procedure AddSalesManagerRoles(ProfileDetails) Export
EndProcedure

Procedure AddRetailManagerRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddCashierRoles(ProfileDetails) Export
EndProcedure

Procedure AddTreasurerRoles(ProfileDetails) Export
EndProcedure

Procedure AddStorekeeperRoles(ProfileDetails) Export
EndProcedure

Procedure AddSchedulingAdministratorRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddRolesForProductionPlanning(ProfileDetails) Export
	
	
EndProcedure

Procedure AddSalesPlanningParticipantRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddSalesForecastingParticipantRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddSalesForecastingAdministratorRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddExternalClientRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddMainDispatcherRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddLocalDispatcherRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddProductionManagerRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddProductionManagerRolesOnSide(ProfileDetails) Export
	
	
EndProcedure

Procedure AddRolesOfManagerForProcessingTollFreeRawMaterials(ProfileDetails) Export
	
	
EndProcedure

Procedure AddOTCControllerRoles(ProfileDetails) Export
	
	
EndProcedure

Procedure AddEconomistProductionRoles(ProfileDetails) Export
	
	
EndProcedure
Procedure CompleteInternationalAccountingAnalystProfile(ProfileDetails) Export
	
	
EndProcedure

Procedure CompleteInternationalAccountingAccountantProfile(ProfileDetails) Export
	
	
EndProcedure

Procedure CompleteUserProfileOfInternationalAccountingReporting(ProfileDetails) Export
	
	
EndProcedure

Procedure AddTechnologistRoles(ProfileDetails) Export
	
	
EndProcedure

#EndRegion
