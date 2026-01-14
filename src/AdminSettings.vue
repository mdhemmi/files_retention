<!--
  - SPDX-FileCopyrightText: Joas Schilling <coding@schilljs.com>
  - SPDX-License-Identifier: AGPL-3.0-only
  -->
<template>
	<NcSettingsSection :name="t('files_retention', 'File retention & automatic deletion')"
		:doc-url="docUrl"
		:description="t('files_retention', 'Define if files tagged with a specific tag should be deleted automatically after some time. This is useful for confidential documents.')">
		<table class="retention-rules-table">
			<thead>
				<tr>
					<th class="retention-heading__name">
						{{ t('files_retention', 'Files tagged with') }}
					</th>
					<th class="retention-heading__time">
						{{ t('files_retention','Retention time') }}
					</th>
					<th class="retention-heading__after">
						{{ t('files_retention','From date of') }}
					</th>
					<th class="retention-heading__action">
						{{ t('files_retention','Action') }}
					</th>
					<th class="retention-heading__action" />
				</tr>
			</thead>
			<tbody>
				<RetentionRule v-for="rule in retentionRules"
					:key="rule.id"
					:tags="tags"
					v-bind="rule">
					{{ rule.tagid }}
				</RetentionRule>

				<tr>
					<td class="retention-rule__name">
						<NcSelectTags v-model="newTag"
							:disabled="loading"
							:multiple="false"
							:clearable="false"
							:options-filter="filterAvailableTagList" />
					</td>
					<td class="retention-rule__time">
						<NcTextField v-model="newAmount"
							:disabled="loading"
							type="text"
							:label="amountLabel"
							:aria-label="amountAriaLabel"
							:placeholder="''" />
						<NcSelect v-model="newUnit"
							:disabled="loading"
							:options="unitOptions"
							:allow-empty="false"
							:clearable="false"
							track-by="id"
							label="label" />
					</td>
					<td class="retention-rule__after">
						<NcSelect v-model="newAfter"
							:disabled="loading"
							:options="afterOptions"
							:allow-empty="false"
							:clearable="false"
							track-by="id"
							label="label" />
					</td>
					<td class="retention-rule__action">
						<div class="retention-rule__action-content">
							<NcSelect v-model="newAction"
								:disabled="loading"
								:options="actionOptions"
								:allow-empty="false"
								:clearable="false"
								track-by="id"
								label="label" />
							<NcTextField v-if="newAction?.id === 2"
								v-model="newMoveToPath"
								:disabled="loading"
								type="text"
								:label="t('files_retention', 'Destination path')"
								:placeholder="t('files_retention', 'e.g., archive/old-files')"
								class="retention-rule__path-input" />
							<div v-if="newAction?.id === 2" class="retention-rule__info">
								{{ t('files_retention', 'Archive folders are automatically hidden from mobile apps (prefixed with dot)') }}
							</div>
						</div>
					</td>
					<td class="retention-rule__action">
						<div class="retention-rule__action--button-aligner">
							<NcButton variant="success"
								:disabled="loading || newTag < 0 || (newAction?.id === 2 && !newMoveToPath.trim())"
								:aria-label="createLabel"
								@click="onClickCreate">
								<template #icon>
									<Plus :size="20" />
								</template>
								{{ t('files_retention', 'Create') }}
							</NcButton>
						</div>
					</td>
				</tr>
			</tbody>
		</table>

		<NcCheckboxRadioSwitch type="switch"
			:model-value="notifyBefore"
			:loading="loadingNotifyBefore"
			@update:modelValue="onToggleNotifyBefore">
			{{ t('files_retention', 'Notify owner a day before a file is automatically deleted') }}
		</NcCheckboxRadioSwitch>
	</NcSettingsSection>
</template>

<script>
import NcButton from '@nextcloud/vue/components/NcButton'
import NcCheckboxRadioSwitch from '@nextcloud/vue/components/NcCheckboxRadioSwitch'
import NcSelect from '@nextcloud/vue/components/NcSelect'
import NcSelectTags from '@nextcloud/vue/components/NcSelectTags'
import NcSettingsSection from '@nextcloud/vue/components/NcSettingsSection'
import NcTextField from '@nextcloud/vue/components/NcTextField'
import Plus from 'vue-material-design-icons/Plus.vue'

import RetentionRule from './Components/RetentionRule.vue'
import { fetchTags } from './services/api.ts'

import { showError, showSuccess, showWarning } from '@nextcloud/dialogs'
import { loadState } from '@nextcloud/initial-state'
import { t } from '@nextcloud/l10n'

export default {
	name: 'AdminSettings',

	components: {
		NcButton,
		NcCheckboxRadioSwitch,
		NcSelect,
		NcSelectTags,
		Plus,
		RetentionRule,
		NcSettingsSection,
		NcTextField,
	},

	data() {
		return {
			loading: true,
			loadingNotifyBefore: false,
			notifyBefore: loadState('files_retention', 'notify_before'),
			docUrl: loadState('files_retention', 'doc-url'),

			unitOptions: [
				{ id: 0, label: t('files_retention', 'Days') },
				{ id: 1, label: t('files_retention', 'Weeks') },
				{ id: 2, label: t('files_retention', 'Months') },
				{ id: 3, label: t('files_retention', 'Years') },
			],
			newUnit: {},

			afterOptions: [
				{ id: 0, label: t('files_retention', 'Creation') },
				{ id: 1, label: t('files_retention', 'Last modification') },
			],
			newAfter: {},

			actionOptions: [
				{ id: 0, label: t('files_retention', 'Delete') },
				{ id: 1, label: t('files_retention', 'Move to trash') },
				{ id: 2, label: t('files_retention', 'Move to path') },
			],
			newAction: {},

			newAmount: '14', // FIXME TextField does not accept numbers …
			newMoveToPath: '',

			newTag: null,
			tagOptions: [],
			filterAvailableTagList: (tag) => {
				return !this.tagIdsWithRule.includes(tag.id)
			},
			tags: [],
		}
	},

	computed: {
		retentionRules() {
			return this.$store.getters.getRetentionRules()
		},

		tagIdsWithRule() {
			return this.$store.getters.getTagIdsWithRule()
		},

		amountLabel() {
			return t('files_retention', 'Time units')
		},

		amountAriaLabel() {
			return t('files_retention', 'Number of days, weeks, months or years after which the files should be deleted')
		},

		createLabel() {
			return t('files_retention', 'Create new retention rule')
		},
	},

	async mounted() {
		try {
			this.tags = await fetchTags()
			await this.$store.dispatch('loadRetentionRules')

			this.resetForm()

			this.loading = false
		} catch (e) {
			showError(t('files_retention', 'An error occurred while loading the existing retention rules'))
			console.error(e)
		}
	},

	methods: {
		t,

		onToggleNotifyBefore() {
			this.loadingNotifyBefore = true
			const newNotifyBefore = !this.notifyBefore

			OCP.AppConfig.setValue(
				'files_retention',
				'notify_before',
				newNotifyBefore ? 'yes' : 'no',
				{
					success: function() {
						if (newNotifyBefore) {
							showSuccess(t('files_retention', 'Users are now notified one day before a file or folder is being deleted'))
						} else {
							showWarning(t('files_retention', 'Users are no longer notified before a file or folder is being deleted'))
						}

						this.loadingNotifyBefore = false
						this.notifyBefore = newNotifyBefore
					}.bind(this),
					error: function() {
						this.loadingNotifyBefore = false
						showError(t('files_retention', 'An error occurred while changing the setting'))
					}.bind(this),
				},
			)
		},

		async onClickCreate() {
			// When the value is unchanged, the Multiselect component returns the initial ID
			// Otherwise the entry from this.unitOptions
			const newTag = this.newTag?.id ?? this.newTag
			const newUnit = this.newUnit?.id ?? this.newUnit
			const newAfter = this.newAfter?.id ?? this.newAfter
			const newAction = this.newAction?.id ?? this.newAction
			const newAmount = parseInt(this.newAmount, 10)

			if (newTag === null || newTag < 0) {
				showError(t('files_retention', 'Invalid tag selected'))
				return
			}

			const tagName = this.tags.find((tag) => tag.id === newTag)?.displayName

			if (this.tagIdsWithRule.includes(newTag)) {
				showError(t('files_retention', 'Tag {tagName} already has a retention rule', { tagName }))
				return
			}

			if (newUnit < 0 || newUnit > 3) {
				showError(t('files_retention', 'Invalid unit option'))
				return
			}

			if (newAfter < 0 || newAfter > 1) {
				showError(t('files_retention', 'Invalid action option'))
				return
			}

			if (newAction < 0 || newAction > 2) {
				showError(t('files_retention', 'Invalid action type'))
				return
			}

			if (newAction === 2 && (!this.newMoveToPath || !this.newMoveToPath.trim())) {
				showError(t('files_retention', 'Destination path is required when moving to path'))
				return
			}

			if (isNaN(newAmount) || newAmount < 1) {
				showError(t('files_retention', 'Invalid retention time'))
				return
			}

			try {
				const ruleData = {
					tagid: newTag,
					timeamount: newAmount,
					timeunit: newUnit,
					timeafter: newAfter,
					actiontype: newAction,
				}
				if (newAction === 2) {
					ruleData.movetopath = this.newMoveToPath.trim()
				}

				await this.$store.dispatch('createNewRule', ruleData)

				showSuccess(t('files_retention', 'Retention rule for tag {tagName} saved', { tagName }))
				this.resetForm()
			} catch (e) {
				showError(t('files_retention', 'Failed to save retention rule for tag {tagName}', { tagName }))
				console.error(e)
			}
		},

		resetForm() {
			this.newTag = null
			this.newAmount = '14'
			this.newUnit = this.unitOptions[0]
			this.newAfter = this.afterOptions[0]
			this.newAction = this.actionOptions[0]
			this.newMoveToPath = ''
		},
	},
}
</script>

<style scoped lang="scss">
	.retention-rules-table {
	width: 100%;
	min-height: 50px;
	padding-top: 5px;
	max-width: 100%;

	.retention-heading,
	.retention-rule {
		&__name,
		&__time,
		&__after,
		&__active,
		&__action {
			color: var(--color-text-maxcontrast);
			padding: 10px 10px 10px 0;
			vertical-align: top;
		}

		&__name {
			min-width: 150px;
		}

		&__time {
			text-align: center;
			min-width: 280px;
		}

		&__after {
			min-width: 150px;
		}

		&__action {
			min-width: 200px;
			padding-left: 10px;

			&--button-aligner {
				margin-top: 6px;
			}
		}
	}

	.retention-heading {
		&__name,
		&__time,
		&__after,
		&__active,
		&__action {
			padding-left: 13px;
		}
	}

	.retention-rule {
		&__time {
			> div {
				width: 49%;
				min-width: 0;
				display: inline-block;
				margin-right: 2%;
			}

			> div:last-child {
				margin-right: 0;
			}

			:deep(.input-field__input) {
				text-align: right;
			}
		}

		&__action {
			&-content {
				display: flex;
				flex-direction: column;
				gap: 8px;
			}

			&--button-aligner {
				display: flex;
				justify-content: flex-end;
			}
		}

		&__path-input {
			margin-top: 8px;
		}

		&__info {
			font-size: 0.85em;
			color: var(--color-text-maxcontrast);
			margin-top: 4px;
			font-style: italic;
			line-height: 1.4;
		}
	}
}
</style>
