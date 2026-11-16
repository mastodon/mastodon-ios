// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonCore
import MastodonLocalization

struct CollectionEditDetailsView: View {
    @Environment(MastodonNavigationRouter.self) private var navigator
    @Environment(CreateCollectionViewModel.self) private var viewModel
    
    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            
            // NAME
            Section {
                TextField(L10nLookup.Scene.CreateCollection.CollectionDetails.namePlaceholder, text: $viewModel.collectionName)
            } header: {
                Text(L10nLookup.Scene.CreateCollection.CollectionDetails.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
                    .accessibilityAddTraits(.isHeader)
            } footer: {
                limitCaption(viewModel.maxCollectionNameLength, isOverLimit: viewModel.nameIsTooLong)
            }
            
            // DESCRIPTION
            Section {
                TextField(L10nLookup.Scene.CreateCollection.CollectionDetails.descriptionPlaceholder, text: $viewModel.collectionDescription, axis: .vertical)
                    .lineLimit(1...4)
            } footer: {
                limitCaption(viewModel.maxCollectionDescriptionLength, isOverLimit: !viewModel.descriptionIsValid)
            }
            
            // TOPIC (hashtag)
            Section {
                TextField(L10nLookup.Scene.CreateCollection.CollectionDetails.topicPlaceholder, text: $viewModel.collectionTopic)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } footer: {
                Text(L10nLookup.Scene.CreateCollection.CollectionDetails.topicHint)
            }
            
            // LANGUAGE
            Section {
                Button {
                    navigator.push(.collectionLanguagePicker(viewModel))
                } label: {
                    NavigationRow(label: L10nLookup.Scene.CreateCollection.CollectionDetails.languagePlaceholder, sublabel: viewModel.languageName ?? L10nLookup.Scene.CreateCollection.CollectionDetails.noLanguageSelected)
                }
            }
            
            // VISIBILITY
            Section(L10nLookup.Scene.CreateCollection.CollectionDetails.Visibility.title) {
                VisibilityRow(
                    title: L10nLookup.Scene.CreateCollection.CollectionDetails.Visibility.publicSetting,
                    subtitle: L10nLookup.Scene.CreateCollection.CollectionDetails.Visibility.publicExplainer,
                    isSelected: viewModel.isDiscoverable
                ) {
                    viewModel.isDiscoverable = true
                }
                
                VisibilityRow(
                    title: L10nLookup.Scene.CreateCollection.CollectionDetails.Visibility.unlistedSetting,
                    subtitle: L10nLookup.Scene.CreateCollection.CollectionDetails.Visibility.unlistedExplainer,
                    isSelected: !viewModel.isDiscoverable
                ) {
                    viewModel.isDiscoverable = false
                }
            }
            
            // SENSITIVE
            Section {
                ToggleRow(label: L10nLookup.Scene.CreateCollection.CollectionDetails.markSensitive, isOn: $viewModel.isSensitive)
            } header: {
                Text(L10nLookup.Scene.CreateCollection.CollectionDetails.contentWarning)
            } footer: {
                Text(L10nLookup.Scene.CreateCollection.CollectionDetails.sensitiveExplainer)
            }
            
            // CREATE BUTTON
            Section {
                createButton
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: maxFeedContentWidth)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
        .createCollectionPageTitle(forStep: .details, mode: viewModel.mode)
        .navigationBarBackButtonHidden(viewModel.isSaving)
    }
    
    @ViewBuilder private var createButton: some View {
        Button {
            viewModel.saveDetails(navigator: navigator)
        } label: {
            if viewModel.isSaving {
                ProgressView()
                    .tint(.white)
            } else {
                switch viewModel.mode {
                case .create:
                    Text(L10nLookup.Scene.CreateCollection.CollectionDetails.createCollection)
                case .edit:
                    Text(L10n.Common.Controls.Actions.save)
                }
            }
        }
        .buttonStyle(CapsuleButtonStyle(viewModel.detailsValid ? .prominent : .subtle, isLarge: true))
        .disabled(!viewModel.detailsValid || viewModel.isSaving)
        .accessibilityLabel(viewModel.mode == .create ? L10nLookup.Scene.CreateCollection.CollectionDetails.createCollection : L10n.Common.Controls.Actions.save)
    }
    
    @ViewBuilder private func limitCaption(_ limit: Int, isOverLimit: Bool) -> some View {
        Text(L10nLookup.Scene.CreateCollection.CollectionDetails.characterLimit(limit))
            .foregroundStyle(isOverLimit ? .red : .secondary)
    }
}

private struct VisibilityRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: doublePadding) {
                Image(systemName: "checkmark")
                    .foregroundStyle(Asset.Colors.accent.swiftUIColor)
                    .accessibilityHidden(true)
                    .opacity(isSelected ? 1 : 0)
                
                VStack(alignment: .leading, spacing: tinySpacing) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
