import { mount } from '@vue/test-utils';
import { describe, expect, test } from 'vitest';
import Badge from '../badge.vue';

const CONTENT = '<div class ="test-content">content</div>';
describe('Badge', () => {
  test('has value', () => {
    const wrapper = mount(Badge, {
      props: {
        value: 20,
      },
    });
    expect(wrapper.find('.sup').text()).toEqual('20');
    // expect(wrapper.find('.el-badge__content').text()).toEqual('80');
  });

  test('has slot', () => {
    const wrapper = mount(Badge, {
      props: {
        value: 20,
      },
      slots: {
        default: () => CONTENT,
      },
    });
    expect(wrapper.html()).toContain(
      '<div class="test-content">content</div>1'
    );
  });
});
